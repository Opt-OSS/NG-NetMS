set(DZIL_ROOT_DIR
	"${DZIL_ROOT_DIR}"
	CACHE
	PATH
	"Directory to start our search in")

find_program(DZIL_COMMAND
	NAMES
	dzil
	HINTS
	"${DZIL_ROOT_DIR}"
	PATH_SUFFIXES
	bin
	libexec)

if(DZIL_COMMAND)
	execute_process(
		COMMAND  dzil 		--version
		#COMMAND		head -n 1
		OUTPUT_VARIABLE DZIL_VERSION OUTPUT_STRIP_TRAILING_WHITESPACE)
	string(REGEX
		REPLACE
		"[^0-9]*([0-9]+[0-9.]*).*"
		"\\1"
		DZIL_VERSION
		"${DZIL_VERSION}")
endif()

# handle the QUIETLY and REQUIRED arguments and set xxx_FOUND to TRUE if
# all listed variables are TRUE
include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(Dzil
	REQUIRED_VARS  DZIL_COMMAND
	VERSION_VAR DZIL_VERSION)

if(DZIL_FOUND)
	mark_as_advanced(DZIL_ROOT_DIR)
	mark_as_advanced(DZIL_COMMAND)
endif()

