# - Find libpqxx
#   Find the libpqxx includes and client library
# This module defines
#  PQXX_INCLUDE_DIRS
#  PQXX_LIBRARIES
#  PQXX_FOUND

include (FindPackageHandleStandardArgs)

find_path (PQXX_INCLUDE_DIRS
    NAME
        pqxx
    PATHS
        /usr/include
        /usr/local/include
    PATH_SUFFIXES
        pqxx
    DOC 
        "Directory for pqxx headers"    
)

find_library (PQXX_LIBRARIES
    NAMES
        pqxx
)

FIND_PACKAGE_HANDLE_STANDARD_ARGS("PQXX"
    "libpqxx couldn't be found"
    PQXX_LIBRARIES
    PQXX_INCLUDE_DIRS
)

mark_as_advanced (PQXX_INCLUDE_DIR PQXX_LIBRARY)
