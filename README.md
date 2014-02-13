# erloci - An Erlang wrapper for the Oracle Call Interface

### Setup the development system
Create a environment variable OTPROOT pointing to erlang installation directory,
e.g. - in linux (if installed from RPM) its usually /usr/lib/erlang.
Download from [Oracle](http://www.oracle.com/technetwork/database/features/instant-client/index-097480.html) the following libraries (for matching os and platfrom for the development system)
  1. instantclient-basic
  2. instantclient-sdk

### Windows
Unzip both into a directory and create the following enviroment variable
E.g. - if your instant client library version is 12.1 and you have unzipped 'instantclient-basic-windows*.zip' to C:\Oracle\instantclient\instantclient_12_1 then the sdk should be at C:\Oracle\instantclient\instantclient_12_1\sdk\
The include headers will be at C:\Oracle\instantclient\instantclient_12_1\sdk\include and static libraries at C:\Oracle\instantclient\instantclient_12_1\sdk\lib\msvc (note the path for VS project configuration later)

### Linux
Use rpms (recomended) to install basic and sdk. The default install path is usually (for x86_64 architecture)
```
OCI Headers     : /usr/include/oracle/12.1/client64/
OCI Libraries   : /usr/lib/oracle/12.1/client64/lib/
```

### Create Environment variables
```
INSTANT_CLIENT_LIB_PATH     = path to oci headers
INSTANT_CLIENT_INCLUDE_PATH = path to oci libraries
```

For example:
```
(x64 Fedora)
INSTANT_CLIENT_LIB_PATH=/usr/lib/oracle/12.1/client64/lib/
INSTANT_CLIENT_INCLUDE_PATH=/usr/include/oracle/12.1/client64/

(x64 Windows 7)
INSTANT_CLIENT_LIB_PATH     = C:\Oracle\instantclient\instantclient_12_1\
```

### Compiling
We assume you have [rebar](https://github.com/basho/rebar) somewhere on your path. Rebar will take care of the Erlang and C++ sources.
<code>rebar compile</code>
Please check the rebar manual for how to add erloci as a dependency to your project.

#### Compiling C++ port in visual studio (2008)
Change/Add the following:
  * In project properties of erloci_drv and erloci_lib 
    * Configuration Properties -> C/C++ -> General -> Additional Include Directories: path-to-instant-client\sdk\include
    * Configuration Properties -> C/C++ -> General -> Additional Include Directories: path-to-instant-client\sdk\include
  * In project property of erloci_lib 
    * Configuration Properties -> Librarian -> General -> Additional Library Directories: path-to-instant-client\sdk\lib\msvc
    * Configuration Properties -> Librarian -> General -> Additional Dependencies: oraocciXX.lib (replace XX with matching file in path)

### 3d party dependencies
#### Threadpool 
The threadpool code (threadpool.cpp/h) is developed by Mathias Brossard mathias@brossard.org. His threadpool library is hosted at https://github.com/mbrossard/threadpool.
This library is unused (not linked) in a Windows environment. For an easier installation process we include the required threadpool files in the erloci repo. So this is NOT a dependency you have to resolve by yourself.

#### Oracle Call Interface (OCI)
OCI provides a high performance, native 'C' language based interface to the Oracle Database. There is no ODBC layer between your application and the database. Since we don't want to distribute the Oracle Code you MUST download the OCI Packages (basic and devel) from the Oracle Website: http://www.oracle.com/technetwork/database/features/instant-client/index-097480.html.

#### Compile ERLOCI in Windows
Make sure you have <code>vcbuild.exe</code> in path. After that <code>rebar compile</code> will take care the rest. Currently erloci can only be build with VS2008.

### Eunit test
The Oracle connection information are taken from erloci.app.src. Please change it to point to your database before executing the steps below:
1. <code>rebar compile</code>
2. <code>rebar eunit</code>

### Work-In-Progess
1. Support Variable binding for Input

### TODOs
1. More test cases
2. In/Out bind variables and arrays
