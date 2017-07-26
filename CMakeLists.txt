cmake_minimum_required (VERSION 2.6)

# Project name
project (NG-NetMS)
# Project version
set( VERSION_MAJOR 3)
set( VERSION_MINOR 62)
set( PROJECT_VERSION "${VERSION_MAJOR}.${VERSION_MINOR}")

IF(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
  SET(CMAKE_INSTALL_PREFIX
    "/opt" CACHE PATH "NGNGMS install prefix" FORCE
    )
ENDIF(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
Set( NGNMS_INSTALL_DIR ${CMAKE_INSTALL_PREFIX}/ngnms)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${CMAKE_CURRENT_SOURCE_DIR}/cmake-modules)
set(CMAKE_DIST_DIR ${CMAKE_BINARY_DIR}/dist)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY  ${CMAKE_DIST_DIR}/bin )
set(PROJECT_SOURCE_PERL_DIR "${PROJECT_SOURCE_DIR}/Core/NGREADY")

find_package(Perl REQUIRED)
find_package(Cpanm REQUIRED)
find_package(NMAP REQUIRED)
# find_package(Cpm REQUIRED)
find_package(Dzil REQUIRED)


# Project settings
INCLUDE(settings.cmake)
############################################################
#                     Preparing c++                        #
#                                                          # 

set(COLLECTOR_CMAKE_INCLUDED ON)
add_subdirectory(CPP/GPL)

#                                                          # 
#                                                          # 
############################################################


############################################################
#                     Preparing perl                       #
#                                                          # 
# Add perl libraries 
message(STATUS "Generating perl Dist::Zilla ini file")
configure_file (  "${PROJECT_SOURCE_PERL_DIR}/dist.ini.in"  "${PROJECT_SOURCE_PERL_DIR}/dist.ini"  @ONLY  )
message(STATUS "Generating env.list")
configure_file (  "${PROJECT_SOURCE_DIR}/env.list.in"  "${CMAKE_DIST_DIR}/env.list"  @ONLY  )
message(STATUS "Generating apache vhost")
configure_file (  "${PROJECT_SOURCE_DIR}/vhost.conf.in"  "${CMAKE_DIST_DIR}/vhost.conf"  @ONLY  )
message(STATUS "Generating crontab file")
configure_file (  "${PROJECT_SOURCE_DIR}/crontab.init.in"  "${CMAKE_DIST_DIR}/crontab.init"  @ONLY  )
message(STATUS "Generating systemd service  file")
configure_file (  "${PROJECT_SOURCE_DIR}/ngnms-audit.service.in"  "${CMAKE_DIST_DIR}/ngnms-audit.service"  @ONLY  )
message(STATUS "Generating nmap sudo file")
configure_file (  "${PROJECT_SOURCE_DIR}/nmap.sudo.in"  "${CMAKE_DIST_DIR}/nmap.sudo"  @ONLY  )


add_custom_command(OUTPUT ${CMAKE_DIST_DIR}/core
  COMMAND dzil build --in ${CMAKE_DIST_DIR}/core
  WORKING_DIRECTORY ${PROJECT_SOURCE_PERL_DIR}
 )
add_custom_target (perl-libs  ALL DEPENDS ${CMAKE_DIST_DIR}/core)
add_custom_target(perl-install-deps 
  command cpanm --quiet --no-man-pages --notest --installdeps .
  WORKING_DIRECTORY ${CMAKE_DIST_DIR}/core
)

# Add perl binaries 
set(PERL_BINARIES
 bin/AppRun.pl          
 bin/archive.pl         
 bin/audit.pl           
 bin/jm-worker.pl       
 bin/log4perl.conf      
 bin/scheduler.pl       
 bin/scheduler.sh
 bin/service_manager.sh
 bin/subnets_scanner.pl 
)
add_custom_command(OUTPUT ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}
  COMMAND  ${CMAKE_COMMAND} -E make_directory   ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}
)
set(_PERL_BINS_DEPS  ${CMAKE_RUNTIME_OUTPUT_DIRECTORY})
#create commands for copying perl-binaries and add as dependency to perl-bins target
foreach(file ${PERL_BINARIES})
  add_custom_command(OUTPUT ${CMAKE_DIST_DIR}/${file}
    COMMAND ${CMAKE_COMMAND} -E copy  ${file} ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/
    WORKING_DIRECTORY ${PROJECT_SOURCE_PERL_DIR}
  )
  LIST(APPEND _PERL_BINS_DEPS   ${CMAKE_DIST_DIR}/${file})
endforeach()
add_custom_target (perl-bins ALL DEPENDS ${_PERL_BINS_DEPS})


#Dockerize
INCLUDE(docker-build/CMakeList.cmake OPTIONAL )

#                                                          # 
#                                                          # 
############################################################
############################################################
#                     Preparing WWW                        #
#         
 
 configure_file (   ${PROJECT_SOURCE_DIR}/Web/www/protected/VERSION.php.in  ${PROJECT_SOURCE_DIR}/Web/www/protected/VERSION.php  @ONLY  )
 add_custom_command(OUTPUT ${CMAKE_DIST_DIR}/Web/www
   COMMAND ${CMAKE_COMMAND} -E copy_directory  Web/www/ ${CMAKE_DIST_DIR}/Web/www
   COMMAND ${CMAKE_COMMAND} -E remove -f  ${CMAKE_DIST_DIR}/Web/www/custom_config/main.php
   WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
  )
 add_custom_target (www  ALL DEPENDS ${CMAKE_DIST_DIR}/Web/www)
#                                                          #
#                                                          #
############################################################


install (DIRECTORY ${CMAKE_RUNTIME_OUTPUT_DIRECTORY} 
   DESTINATION ${NGNMS_INSTALL_DIR}
   FILE_PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ GROUP_EXECUTE GROUP_READ
   DIRECTORY_PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ GROUP_EXECUTE GROUP_READ GROUP_EXECUTE
   )
install (DIRECTORY ${CMAKE_DIST_DIR}/core/database
   DESTINATION ${NGNMS_INSTALL_DIR}
   PATTERN "*.sh"
        PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ
                    GROUP_EXECUTE GROUP_READ
   PATTERN "*.pl"
        PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ
                    GROUP_EXECUTE GROUP_READ
 )
install (DIRECTORY ${CMAKE_DIST_DIR}/core/rules
   DESTINATION ${NGNMS_INSTALL_DIR}
 )
install (DIRECTORY ${CMAKE_DIST_DIR}/core/triggers
   DESTINATION ${NGNMS_INSTALL_DIR}
 )

install (FILES 
  ${CMAKE_DIST_DIR}/core/cpanfile
  ${CMAKE_DIST_DIR}/core/LICENSE
  ${CMAKE_DIST_DIR}/env.list 
  ${CMAKE_DIST_DIR}/vhost.conf 
  ${CMAKE_DIST_DIR}/crontab.init 
  ${CMAKE_DIST_DIR}/ngnms-audit.service
  ${CMAKE_DIST_DIR}/nmap.sudo
  DESTINATION ${NGNMS_INSTALL_DIR}
  )
#   
 install (DIRECTORY ${CMAKE_DIST_DIR}/core/lib
   DESTINATION ${NGNMS_INSTALL_DIR}
 )
 install(DIRECTORY DESTINATION ${NGNMS_INSTALL_DIR}/data DIRECTORY_PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ  GROUP_READ GROUP_EXECUTE)
 install(DIRECTORY DESTINATION ${NGNMS_INSTALL_DIR}/archive)
 install(DIRECTORY DESTINATION ${NGNMS_INSTALL_DIR}/data/rtconfig)
 install(DIRECTORY DESTINATION ${NGNMS_INSTALL_DIR}/data/topologies)
 install(DIRECTORY DESTINATION ${NGNMS_INSTALL_DIR}/logs DIRECTORY_PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ GROUP_WRITE GROUP_READ  GROUP_EXECUTE)
 install(DIRECTORY DESTINATION ${NGNMS_INSTALL_DIR}/tmp DIRECTORY_PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ GROUP_WRITE GROUP_READ GROUP_EXECUTE)
########### installing Web
 install(DIRECTORY ${CMAKE_DIST_DIR}/Web/www
 DESTINATION ${NGNMS_INSTALL_DIR}  DIRECTORY_PERMISSIONS
 OWNER_WRITE OWNER_READ OWNER_EXECUTE
    GROUP_READ GROUP_EXECUTE
  FILE_PERMISSIONS  OWNER_WRITE OWNER_READ  GROUP_READ
  REGEX "protected/runtime|protected/tmp|html/assets" EXCLUDE
 )
install(DIRECTORY DESTINATION ${NGNMS_INSTALL_DIR}/www/protected/runtime DIRECTORY_PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ GROUP_WRITE GROUP_READ GROUP_EXECUTE)
install(DIRECTORY DESTINATION ${NGNMS_INSTALL_DIR}/www/protected/tmp DIRECTORY_PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ GROUP_WRITE GROUP_READ GROUP_EXECUTE)
install(DIRECTORY DESTINATION ${NGNMS_INSTALL_DIR}/www/html/assets DIRECTORY_PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ GROUP_WRITE GROUP_READ GROUP_EXECUTE)

#--no-man-pages --notest --installdeps

