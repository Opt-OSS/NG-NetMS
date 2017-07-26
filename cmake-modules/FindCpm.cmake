set(CPM_ROOT_DIR
	"${CPM_ROOT_DIR}"
	CACHE
	PATH
	"Directory to start our search in")

find_program(CPM_COMMAND
	NAMES
	cpm
	HINTS
	"${CPM_ROOT_DIR}"
	PATH_SUFFIXES
	bin
	libexec)

if(CPM_COMMAND)
	execute_process(
		COMMAND  cpm 		--version
		#COMMAND		head -n 1
		OUTPUT_VARIABLE CPM_VERSION OUTPUT_STRIP_TRAILING_WHITESPACE)
	string(REGEX
		REPLACE
		"[^0-9]*([0-9]+[0-9.]*).*"
		"\\1"
		CPM_VERSION
		"${CPM_VERSION}")
endif()

# handle the QUIETLY and REQUIRED arguments and set xxx_FOUND to TRUE if
# all listed variables are TRUE
include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(Cpm
	REQUIRED_VARS  CPM_COMMAND
	VERSION_VAR CPM_VERSION)

if(CPM_FOUND)
	mark_as_advanced(CPM_ROOT_DIR)
	mark_as_advanced(CPM_COMMAND)
endif()

