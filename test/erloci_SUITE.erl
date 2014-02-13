-module(erloci_SUITE).
-export([all/0, init_per_suite/1, end_per_suite/1]).
-export([load/1]).

-include_lib("common_test/include/ct.hrl").

-define(value(Key,Config), proplists:get_value(Key,Config)).
-define(TAB, "erloci_load").
-define(PROCESSES, 1).
-define(ROWS_PER_TABLE, 10000).

all() -> [load].

init_per_suite(InitConfigData) ->
    Tables = [lists:flatten([?TAB,"_",integer_to_list(I)]) || I <- lists:seq(1, ?PROCESSES)],
    ct:pal(info, "Building ~p rows to bind for ~p tables", [?ROWS_PER_TABLE, length(Tables)]),
    Binds = [{ I
     , list_to_binary(["_publisher_",integer_to_list(I),"_"])
     , I+I/2
     , list_to_binary(["_hero_",integer_to_list(I),"_"])
     , list_to_binary(["_reality_",integer_to_list(I),"_"])
     , I
     , oci_util:edatetime_to_ora(erlang:now())
     , I
     } || I <- lists:seq(1, ?ROWS_PER_TABLE)],
    ct:pal(info, "Starting ~p processes", [length(Tables)]),
    [{tables, Tables}, {binds, Binds} | InitConfigData].

end_per_suite(ConfigData) ->
    ct:pal(info, "Finishing...", []).

load(ConfigData) ->
    Tables = ?value(tables, ConfigData),
    Binds = ?value(binds, ConfigData),
    RowsPerProcess = length(Binds),
    {OciPort, OciSession} = oci_test:setup(),
    ct:pal(info, "Starting ~p processes each for ~p rows", [length(Tables), RowsPerProcess]),
    This = self(),
    [spawn(fun() ->
        tab_setup(OciSession, Table),
        tab_load(OciSession, Table, RowsPerProcess, Binds),
        tab_access(OciSession, Table, 1000),
        This ! Table
     end)
    || Table <- Tables],
    collect_processes(lists:sort(Tables), []),
    ct:pal(info, "Closing session ~p", [OciSession]),
    ok = OciSession:close(),
    ct:pal(info, "Closing port ~p", [OciPort]),
    ok = OciPort:close().

collect_processes(Tables, Acc) ->
    receive
        Table ->
            case lists:sort([Table | Acc]) of
                Tables -> ok;
                NewAcc -> collect_processes(Tables, Acc)
            end
    end.

-define(B(__L), list_to_binary(__L)).
-define(CREATE(__T), ?B([
    "create table "
    , __T
    , " (pkey integer,"
    , "publisher varchar2(30),"
    , "rank float,"
    , "hero varchar2(30),"
    , "reality varchar2(30),"
    , "votes number(1,-10),"
    , "createdate date default sysdate,"
    , "chapters int,"
    , "votes_first_rank number)"])
).
-define(INSERT(__T), ?B([
    "insert into "
    , __T
    , " (pkey,publisher,rank,hero,reality,votes,createdate,votes_first_rank) values ("
    , ":pkey"
    , ", :publisher"
    , ", :rank"
    , ", :hero"
    , ", :reality"
    , ", :votes"
    , ", :createdate"
    , ", :votes_first_rank)"])
).
-define(BIND_LIST, [
    {<<":pkey">>, 'SQLT_INT'}
    , {<<":publisher">>, 'SQLT_CHR'}
    , {<<":rank">>, 'SQLT_FLT'}
    , {<<":hero">>, 'SQLT_CHR'}
    , {<<":reality">>, 'SQLT_CHR'}
    , {<<":votes">>, 'SQLT_INT'}
    , {<<":createdate">>, 'SQLT_DAT'}
    , {<<":votes_first_rank">>, 'SQLT_INT'}
    ]
).
-define(SELECT_WITH_ROWID(__T), ?B([
    "select ",__T,".rowid, ",__T,".* from ",__T])
).

tab_setup(OciSession, Table) when is_list(Table) ->
    ct:pal(info, "[~s] Dropping...", [Table]),
    DropStmt = OciSession:prep_sql(?B(["drop table ", Table])),
    {oci_port, statement, _, _, _} = DropStmt,
    case DropStmt:exec_stmt() of
        {error, _} -> ok; 
        _ -> ok = DropStmt:close()
    end,
    ct:pal(info, "[~s] Creating...", [Table]),
    StmtCreate = OciSession:prep_sql(?CREATE(Table)),
    {oci_port, statement, _, _, _} = StmtCreate,
    {executed, 0} = StmtCreate:exec_stmt(),
    ok = StmtCreate:close(),
    ct:pal(info, "[~s] setup complete...", [Table]).

tab_load(OciSession, Table, RowCount, Binds) ->
    ct:pal(info, "[~s] Loading ~p rows", [Table, RowCount]),
    BoundInsStmt = OciSession:prep_sql(?INSERT(Table)),
    {oci_port, statement, _, _, _} = BoundInsStmt,
    BoundInsStmtRes = BoundInsStmt:bind_vars(?BIND_LIST),
    ok = BoundInsStmtRes,
    {rowids, RowIds} = BoundInsStmt:exec_stmt(Binds),
    RowCount = length(RowIds),
    ok = BoundInsStmt:close(),
    ok.

tab_access(OciSession, Table, Count) ->
    ct:pal(info, "[~s]  Loading rows @ ~p per fetch", [Table, Count]),
    SelStmt = OciSession:prep_sql(?SELECT_WITH_ROWID(Table)),
    {oci_port, statement, _, _, _} = SelStmt,
    {cols, Cols} = SelStmt:exec_stmt(),
    ct:pal(info, "[~s] Selected columns ~p", [Table, Cols]),
    10 = length(Cols),
    load_rows_to_end(Table, SelStmt:fetch_rows(Count), SelStmt, Count, 0),
    ok = SelStmt:close(),
    ok.

load_rows_to_end(Table, {{rows, Rows}, true}, _, _, Total) ->
    ct:pal(info, "[~s] Loaded ~p rows - Finished", [Table, Total]);
load_rows_to_end(Table, {{rows, Rows}, false}, SelStmt, Count, Total) ->
    Loaded = length(Rows),
    ct:pal(info, "[~s] Loaded ~p / ~p", [Loaded, Total]),
    load_rows_to_end(Table, SelStmt:fetch_rows(Count), SelStmt, Count, Total+Loaded).
