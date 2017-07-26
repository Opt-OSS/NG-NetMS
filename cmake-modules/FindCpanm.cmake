set(CPANM_ROOT_DIR
	"${CPANM_ROOT_DIR}"
	CACHE
	PATH
	"Directory to start our search in")

find_program(CPANM_COMMAND
	NAMES
	cpanm
	HINTS
	"${CPANM_ROOT_DIR}"
	PATH_SUFFIXES
	bin
	libexec)

if(CPANM_COMMAND)
	execute_process(
		COMMAND  cpanm 		--version
		#COMMAND		head -n 1
		OUTPUT_VARIABLE CPANM_VERSION OUTPUT_STRIP_TRAILING_WHITESPACE)
	string(REGEX
		REPLACE
		"[^0-9]*([0-9]+[0-9.]*).*"
		"\\1"
		CPANM_VERSION
		"${CPANM_VERSION}")
endif()

# handle the QUIETLY and REQUIRED arguments and set xxx_FOUND to TRUE if
# all listed variables are TRUE
include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(Cpanm
	REQUIRED_VARS  CPANM_COMMAND
	VERSION_VAR CPANM_VERSION)

if(CPANM_FOUND)
	mark_as_advanced(CPANM_ROOT_DIR)
	mark_as_advanced(CPANM_COMMAND)
else()
	message(SEND_ERROR
				"ERROR: Could not detect cpamnimus package")	
endif()

