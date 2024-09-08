cmake_minimum_required (VERSION 2.6)


# Project name
project (NG-NetMS)
IF (NOT COLLECTOR_CMAKE_INCLUDED)
    # Project version
    set( VERSION_MAJOR 3)
    set( VERSION_MINOR 623)

    # Project settings
    set( DB_CFG_FILE_NAME "db.cfg")
    set( DB_HOST          "localhost" )
    set( DB_PORT           5432 )
    set( DB_NAME          "ngnms" )
    set( DB_USER          "ngnms" )
    set( DB_PASSWORD      "ngnms" )
    set( DB_TIMEOUT	       10 )
    set( HOME_ENV         "NGNMS_HOME" )
    # Put all binaries to bin directory 
    set( CMAKE_RUNTIME_OUTPUT_DIRECTORY "bin/" )

ENDIF()



if ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "GNU")
    if ("${CMAKE_CXX_COMPILER_VERSION}" VERSION_LESS "4.8")
       message(FATAL_ERROR "
    ### You appear to be using GCC ${CMAKE_CXX_COMPILER_VERSION}, which isknown to be
    ### unable to compile NGNMS. Only GCC >= 4.8 is supported.
    ### Consider using a more recent GCC
    ### If a more recent compiler is already installed on your
    ### system, you can tell CMake to use it with
    ###
    ###     cmake .. -DCMAKE_CXX_COMPILER=/path/to/compiler
        ")
    endif()
else()
       message(FATAL_ERROR "
    ### You appear to be using NOT GNU GCC ${CMAKE_CXX_COMPILER_VERSION}, which isknown to be
    ### unable to compile NGNMS. Only y GCC >= 4.8 is supported.
        ")
endif()


# Multithread support
set(THREADS_PREFER_PTHREAD_FLAG ON)

#Binaries names
set( NGNETMS_BIN_DB_SETTINGS ngnetms_db )
# set( NGNETMS_BIN_DISCOVERY_SETTINGS ngnetms_discovery )
set( NGNETMS_BIN_COLLECTOR ngnetms_collector )
set( NGNETMS_BIN_OBSERVER ngnetms_observer )
set( NGNETMS_BIN_OPTPRF ngnetms_opt_prf )

# Compilation Timestamp 
string( TIMESTAMP BUILD_DATE "%Y-%m-%d" )
string( TIMESTAMP BUILD_TIME "%H:%M:%S" )


# Make configuration file from template
configure_file ( ${CMAKE_CURRENT_SOURCE_DIR}/common/Configuration.h.in ${CMAKE_CURRENT_SOURCE_DIR}/common/Configuration.h )
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${CMAKE_CURRENT_SOURCE_DIR}/cmake-modules)  
#Common sources
set(COMMON_SRC 
common/ConfigFileReader.cpp
common/ConfigFileWriter.cpp
common/Cryptography.cpp 
common/DbConnector.cpp 
common/MessageQueue.cpp
common/LogWriter.cpp)

# Sources DbSettings
set (DB_SETTINGS_SRC 
sources/db_settings/NgnmsDbSettings.cpp )

# # Sources DiscoverySettings
# set (DISCOVERY_SETTINGS_SRC 
# sources/discovery_settings/NgnmsDbSettings.cpp
# sources/discovery_settings/Database.cpp )

set (EVENT_COLLECTOR_INC 
sources/event_collector/SyslogDPs/
sources/event_collector/NetFlowDPs/ 
sources/event_collector/ApacheDPs/
sources/event_collector/SnmpParser/
sources/event_collector/CANParser/
sources/event_collector/SyslogParser/
sources/event_collector/RuleParser/
sources/event_collector/NetFlowParser/
sources/event_collector/ApacheParser/
sources/event_collector/Custom1Parser/
sources/event_collector/Custom2Parser/)

# Sources Event collector
set (EVENT_COLLECTOR_SRC 
sources/event_collector/SyslogDPs/SyslogFileDP.cpp
sources/event_collector/SyslogDPs/SyslogFilePollingDP.cpp
sources/event_collector/SyslogDPs/SyslogTcpDP.cpp
sources/event_collector/SyslogDPs/SyslogUdpDP.cpp
sources/event_collector/SyslogParser/JunosFacilityGroups.cpp
sources/event_collector/SyslogParser/ParserSyslog.cpp
sources/event_collector/SnmpParser/SnmpParser.cpp
sources/event_collector/CANParser/CANParser.cpp
sources/event_collector/CANParser/CANGlobalsParser.hpp
sources/event_collector/NetFlowDPs/TcpServer.cpp
sources/event_collector/NetFlowDPs/NetFlowTcpDP.cpp
sources/event_collector/NetFlowDPs/NetFlowUdpDP.cpp
sources/event_collector/NetFlowParser/NetFlowParser.cpp
sources/event_collector/NetFlowParser/NetFlowV5Parser.cpp
sources/event_collector/ApacheDPs/ApacheFileDP.cpp
sources/event_collector/ApacheDPs/ApacheFilePollingDP.cpp
sources/event_collector/ApacheParser/ApacheParser.cpp
sources/event_collector/Custom1Parser/Custom1Parser.cpp
sources/event_collector/Custom2Parser/Custom2Parser.cpp
sources/event_collector/RuleParser/RulesFileParser.cpp
sources/event_collector/RuleParser/RulesYacc.tab.c
sources/event_collector/RuleParser/lex.yy.c
sources/event_collector/Options.cpp
sources/event_collector/Triggers.cpp
sources/event_collector/Classifier.cpp
sources/event_collector/EventDecorator.hpp
sources/event_collector/Database.cpp
sources/event_collector/EventCollector.cpp
sources/event_collector/Logger.cpp
sources/event_collector/EventType.cpp
sources/event_collector/FilePollReader.cpp)

# Sources Observer
set (OBSERVER_SRC
sources/observer/Database.cpp
sources/observer/Initializer.cpp
sources/observer/main.cpp
sources/observer/Model.cpp
sources/observer/ObserverOptions.cpp
sources/observer/Origin.cpp
sources/observer/OriginManager.cpp
sources/observer/Profiler.cpp
sources/observer/SnmpObserver.cpp
sources/observer/SnmpOption.cpp)


# Sources Observer Profiler
set (OPT_PRF_SRC
sources/option_profiler/Database.cpp
sources/option_profiler/OptionProfiler.cpp
sources/option_profiler/OptPrfOptions.cpp
sources/option_profiler/Logger.cpp
)

#Compiler settings
add_definitions("-std=c++0x")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -pedantic -Wextra")
set(CMAKE_CXX_FLAGS "-O3")        ## Optimize
set(CMAKE_EXE_LINKER_FLAGS "-s")  ## Strip binary

find_package(PkgConfig REQUIRED)
# PQXX
find_package(PCRE REQUIRED)
find_package(PQXX REQUIRED)
find_package(FLEX REQUIRED)
find_package(NETSNMP REQUIRED)
#find_package(Librt REQUIRED)

# find_package(PkgConfig REQUIRED)
# pkg_check_modules(PQXX REQUIRED libpqxx)
# include_directories(${PQXX_INCLUDE_DIRS})
# link_directories(${PQXX_LIBRARY_DIRS})
# add_definitions(${PQXX_CFLAGS_OTHER})

# CRYPTO++
pkg_check_modules(CRYPTOPP libcrypto++ QUIET)
IF( CRYPTOPP_FOUND )
    include_directories(${CRYPTOPP_INCLUDE_DIRS})
    link_directories(${CRYPTOPP_LIBRARY_DIRS})
    add_definitions(${CRYPTOPP_CFLAGS_OTHER})
ELSE()
    pkg_check_modules(CRYPTOPP REQUIRED cryptopp)
    include_directories(${CRYPTOPP_INCLUDE_DIRS})
    link_directories(${CRYPTOPP_LIBRARY_DIRS})
    add_definitions(${CRYPTOPP_CFLAGS_OTHER})
    add_definitions(-DWITH_CRYPTOPP_PP=1)

ENDIF()
#POCO C++ for Event generator only!!!
#include_directories(/usr/local/Poco/include)
#link_directories(/usr/local/Poco/lib)

# Boost
set(Boost_USE_STATIC_LIBS ON)
FIND_PACKAGE(Boost 1.43 COMPONENTS system thread filesystem program_options regex QUIET)
IF( Boost_FOUND )
   INCLUDE_DIRECTORIES(${BOOST_INCLUDE_DIR})
   LINK_DIRECTORIES(${Boost_LIBRARY_DIRS})
ELSE()
   set( Boost_LIBRARIES boost_system boost_thread boost_filesystem boost_program_options boost_regex)
   INCLUDE_DIRECTORIES(/usr/include)
   LINK_DIRECTORIES(/usr/lib64)
ENDIF()


#Common Includes
include_directories(common)
include_directories(sources/event_collector/SyslogDPs/)
include_directories(sources/event_collector/NetFlowDPs/)
include_directories(sources/event_collector)

# Common sources static library
add_library( CommonStatLib STATIC ${COMMON_SRC} )

# Binary DbSettings
add_executable( ${NGNETMS_BIN_DB_SETTINGS} ${DB_SETTINGS_SRC} ) 
target_link_libraries( ${NGNETMS_BIN_DB_SETTINGS} CommonStatLib )
target_link_libraries( ${NGNETMS_BIN_DB_SETTINGS} ${PQXX_LIBRARIES} )
target_link_libraries( ${NGNETMS_BIN_DB_SETTINGS} ${CRYPTOPP_LIBRARIES} )
target_link_libraries( ${NGNETMS_BIN_DB_SETTINGS} ${Boost_LIBRARIES} )

# # Binary DiscoverySettings
# add_executable( ${NGNETMS_BIN_DISCOVERY_SETTINGS} ${DISCOVERY_SETTINGS_SRC} ) 
# target_link_libraries( ${NGNETMS_BIN_DISCOVERY_SETTINGS} CommonStatLib )
# target_link_libraries( ${NGNETMS_BIN_DISCOVERY_SETTINGS} ${PQXX_LIBRARIES} )
# target_link_libraries( ${NGNETMS_BIN_DISCOVERY_SETTINGS} ${CRYPTOPP_LIBRARIES} )
# target_link_libraries( ${NGNETMS_BIN_DISCOVERY_SETTINGS} ${Boost_LIBRARIES} )

# Binary EventCollector
add_executable( ${NGNETMS_BIN_COLLECTOR} ${EVENT_COLLECTOR_SRC} ) 

target_link_libraries( ${NGNETMS_BIN_COLLECTOR} CommonStatLib )
target_link_libraries( ${NGNETMS_BIN_COLLECTOR} ${PQXX_LIBRARIES} )
target_link_libraries( ${NGNETMS_BIN_COLLECTOR} ${CRYPTOPP_LIBRARIES} )
target_link_libraries( ${NGNETMS_BIN_COLLECTOR} ${Boost_LIBRARIES} )
target_link_libraries( ${NGNETMS_BIN_COLLECTOR} pcre fl pthread)
target_include_directories( ${NGNETMS_BIN_COLLECTOR} PUBLIC ${EVENT_COLLECTOR_INC} )


# Binary Observer
add_executable( ${NGNETMS_BIN_OBSERVER} ${OBSERVER_SRC} ) 
target_link_libraries( ${NGNETMS_BIN_OBSERVER} CommonStatLib )
target_link_libraries( ${NGNETMS_BIN_OBSERVER} ${PQXX_LIBRARIES} )
target_link_libraries( ${NGNETMS_BIN_OBSERVER} ${CRYPTOPP_LIBRARIES} )
target_link_libraries( ${NGNETMS_BIN_OBSERVER} ${Boost_LIBRARIES} )
target_link_libraries( ${NGNETMS_BIN_OBSERVER} netsnmp )
target_link_libraries( ${NGNETMS_BIN_OBSERVER} rt )

# Binary Option Profiler
add_executable( ${NGNETMS_BIN_OPTPRF} ${OPT_PRF_SRC} ) 
target_link_libraries( ${NGNETMS_BIN_OPTPRF} CommonStatLib )
target_link_libraries( ${NGNETMS_BIN_OPTPRF} ${PQXX_LIBRARIES} )
target_link_libraries( ${NGNETMS_BIN_OPTPRF} ${CRYPTOPP_LIBRARIES} )
target_link_libraries( ${NGNETMS_BIN_OPTPRF} ${Boost_LIBRARIES} )
target_link_libraries( ${NGNETMS_BIN_OPTPRF} rt )