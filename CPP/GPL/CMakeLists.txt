cmake_minimum_required (VERSION 2.6)

# Project name
project (NG-NetMS)

# Project version
set( VERSION_MAJOR 3)
set( VERSION_MINOR 4)

# Project settings
set( DB_CFG_FILE_NAME "db.cfg")
set( DB_HOST          "localhost" )
set( DB_PORT           5432 )
set( DB_NAME          "ngnms" )
set( DB_USER          "ngnms" )
set( DB_PASSWORD      "ngnms" )
set( DB_TIMEOUT	       10 )
set( HOME_ENV         "NGNMS_HOME" )

# Multithread support
set(THREADS_PREFER_PTHREAD_FLAG ON)

#Binaries names
set( NGNETMS_BIN_DB_SETTINGS ngnetms_db )
set( NGNETMS_BIN_DISCOVERY_SETTINGS ngnetms_discovery )
set( NGNETMS_BIN_COLLECTOR ngnetms_collector )

# Compilation Timestamp 
string( TIMESTAMP BUILD_DATE "%Y-%m-%d" )
string( TIMESTAMP BUILD_TIME "%H:%M:%S" )

# Put all binaries to bin directory 
set( CMAKE_RUNTIME_OUTPUT_DIRECTORY "bin/" )

# Make configuration file from template
configure_file ( common/Configuration.h.in common/Configuration.h )
  
#Common sources
set(COMMON_SRC 
common/ConfigFileReader.cpp
common/ConfigFileWriter.cpp
common/Cryptography.cpp 
common/DbConnector.cpp 
common/MessageQueue.cpp)

# Sources DbSettings
set (DB_SETTINGS_SRC 
sources/db_settings/NgnmsDbSettings.cpp )

# Sources DiscoverySettings
set (DISCOVERY_SETTINGS_SRC 
sources/discovery_settings/NgnmsDbSettings.cpp
sources/discovery_settings/Database.cpp )

# Sources Event collector
set (EVENT_COLLECTOR_SRC 
sources/event_collector/ParserSnmp.cpp
sources/event_collector/RulesFileParser.cpp
sources/event_collector/TcpDataProvider.cpp
sources/event_collector/CollectorOptions.cpp
sources/event_collector/Triggers.cpp
sources/event_collector/FilePollingDataProvider.cpp
sources/event_collector/JunosFacilityGroups.cpp
sources/event_collector/Classifier.cpp
sources/event_collector/ParserSyslog.cpp
sources/event_collector/UdpDataProvider.cpp
sources/event_collector/Database.cpp
sources/event_collector/EventCollector.cpp
sources/event_collector/Logger.cpp
sources/event_collector/EventType.cpp
sources/event_collector/FileDataProvider.cpp
sources/event_collector/RulesYacc.cpp
sources/event_collector/RulesLex.cpp )

#Compiler settings
add_definitions("-std=c++0x")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -pedantic -Wextra")
set(CMAKE_CXX_FLAGS "-O3")        ## Optimize
set(CMAKE_EXE_LINKER_FLAGS "-s")  ## Strip binary

# GTKMM 3.0
find_package(PkgConfig REQUIRED)
pkg_check_modules(GTK3MM REQUIRED gtkmm-3.0)
include_directories(${GTK3MM_INCLUDE_DIRS})
link_directories(${GTK3MM_LIBRARY_DIRS})
add_definitions(${GTK3MM_CFLAGS_OTHER})

# PQXX
find_package(PkgConfig REQUIRED)
pkg_check_modules(PQXX REQUIRED libpqxx)
include_directories(${PQXX_INCLUDE_DIRS})
link_directories(${PQXX_LIBRARY_DIRS})
add_definitions(${PQXX_CFLAGS_OTHER})

# CRYPTO++
pkg_check_modules(CRYPTOPP REQUIRED libcrypto++)
include_directories(${CRYPTOPP_INCLUDE_DIRS})
link_directories(${CRYPTOPP_LIBRARY_DIRS})
add_definitions(${CRYPTOPP_CFLAGS_OTHER})
#include_directories(/usr/include/crypto++)

#POCO C++ for Event generator only!!!
include_directories(/usr/local/Poco/include)
link_directories(/usr/local/Poco/lib)

# Boost
FIND_PACKAGE(Boost 1.43 COMPONENTS system thread filesystem program_options regex REQUIRED)
INCLUDE_DIRECTORIES(${BOOST_INCLUDE_DIR})
LINK_DIRECTORIES(${Boost_LIBRARY_DIRS})

#Common Includes
include_directories(common)

# Common sources static library
add_library( CommonStatLib STATIC ${COMMON_SRC} )

# Binary DbSettings
add_executable( ${NGNETMS_BIN_DB_SETTINGS} ${DB_SETTINGS_SRC} ) 
target_link_libraries( ${NGNETMS_BIN_DB_SETTINGS} CommonStatLib )
target_link_libraries( ${NGNETMS_BIN_DB_SETTINGS} ${PQXX_LIBRARIES} )
target_link_libraries( ${NGNETMS_BIN_DB_SETTINGS} ${CRYPTOPP_LIBRARIES} )
target_link_libraries( ${NGNETMS_BIN_DB_SETTINGS} ${Boost_LIBRARIES} )

# Binary DiscoverySettings
add_executable( ${NGNETMS_BIN_DISCOVERY_SETTINGS} ${DISCOVERY_SETTINGS_SRC} ) 
target_link_libraries( ${NGNETMS_BIN_DISCOVERY_SETTINGS} CommonStatLib )
target_link_libraries( ${NGNETMS_BIN_DISCOVERY_SETTINGS} ${PQXX_LIBRARIES} )
target_link_libraries( ${NGNETMS_BIN_DISCOVERY_SETTINGS} ${CRYPTOPP_LIBRARIES} )
target_link_libraries( ${NGNETMS_BIN_DISCOVERY_SETTINGS} ${Boost_LIBRARIES} )

# Binary EventCollector
add_executable( ${NGNETMS_BIN_COLLECTOR} ${EVENT_COLLECTOR_SRC} ) 
target_link_libraries( ${NGNETMS_BIN_COLLECTOR} CommonStatLib )
target_link_libraries( ${NGNETMS_BIN_COLLECTOR} ${PQXX_LIBRARIES} )
target_link_libraries( ${NGNETMS_BIN_COLLECTOR} ${CRYPTOPP_LIBRARIES} )
target_link_libraries( ${NGNETMS_BIN_COLLECTOR} ${Boost_LIBRARIES} )
target_link_libraries( ${NGNETMS_BIN_COLLECTOR} pcre fl )

