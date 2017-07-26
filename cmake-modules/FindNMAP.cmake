find_program(NMAP_EXECUTABLE
	NAMES nmap
	PATH_SUFFIXES	bin	libexec
  )
if(NMAP_EXECUTABLE)
  ### NMAP_VERSION
  execute_process(
    COMMAND
      ${NMAP_EXECUTABLE} --version
    COMMAND		head -n 2 
      OUTPUT_VARIABLE  NMAP_VERSION  OUTPUT_STRIP_TRAILING_WHITESPACE
  )
  	string(REGEX
		REPLACE
		"[^0-9]*([0-9]+[0-9.]*).*"
		"\\1"
		NMAP_VERSION
		"${NMAP_VERSION}")
endif()


include(FindPackageHandleStandardArgs)
FIND_PACKAGE_HANDLE_STANDARD_ARGS(NMAP
                                  REQUIRED_VARS NMAP_EXECUTABLE
                                  VERSION_VAR NMAP_VERSION)

mark_as_advanced(NMAP_EXECUTABLE)