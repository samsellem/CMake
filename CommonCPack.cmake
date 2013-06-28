
# Copyright (c) 2012-2013 Stefan Eilemann <eile@eyescale.ch>
# Info: http://www.itk.org/Wiki/CMake:Component_Install_With_CPack

if(NOT CPACK_PROJECT_NAME)
  set(CPACK_PROJECT_NAME ${CMAKE_PROJECT_NAME})
endif()
string(TOUPPER ${CPACK_PROJECT_NAME} UPPER_PROJECT_NAME)
string(TOLOWER ${CPACK_PROJECT_NAME} LOWER_PROJECT_NAME)

if(NOT CPACK_PACKAGE_NAME)
  set(CPACK_PACKAGE_NAME ${CPACK_PROJECT_NAME})
endif()

if(CMAKE_SYSTEM_NAME MATCHES "Linux")
  configure_file(${CMAKE_SOURCE_DIR}/CMake/${CMAKE_PROJECT_NAME}.in.spec
    ${CMAKE_SOURCE_DIR}/CMake/${CMAKE_PROJECT_NAME}.spec @ONLY)

  string(TOLOWER ${CPACK_PACKAGE_NAME} LOWER_PACKAGE_NAME_PREFIX)
  set(CPACK_PACKAGE_NAME "${LOWER_PACKAGE_NAME_PREFIX}${VERSION_ABI}")
  set(OLD_PACKAGES)
  foreach(i RANGE ${VERSION_ABI})
    list(APPEND OLD_PACKAGES "${LOWER_PACKAGE_NAME_PREFIX}${i},")
  endforeach()
  list(APPEND OLD_PACKAGES "${LOWER_PACKAGE_NAME_PREFIX}")
  string(REGEX REPLACE ";" " " OLD_PACKAGES ${OLD_PACKAGES})
endif()

if(NOT APPLE)
  # deb lintian insists on URL
  set(CPACK_PACKAGE_VENDOR "http://${CPACK_PACKAGE_VENDOR}")
endif()

set(CPACK_PACKAGE_VERSION_MAJOR ${VERSION_MAJOR})
set(CPACK_PACKAGE_VERSION_MINOR ${VERSION_MINOR})
set(CPACK_PACKAGE_VERSION_PATCH ${VERSION_PATCH})
set(CPACK_PACKAGE_VERSION ${VERSION})
set(CPACK_RESOURCE_FILE_LICENSE ${CMAKE_SOURCE_DIR}/LICENSE.txt)
if(NOT CPACK_PACKAGE_LICENSE)
  set(CPACK_PACKAGE_LICENSE "LGPL")
  message(STATUS "Using default ${CPACK_PACKAGE_LICENSE} package license")
endif()
if(NOT CPACK_PACKAGE_CONFIG_REQUIRES)
  set(CPACK_PACKAGE_CONFIG_REQUIRES ${${UPPER_PROJECT_NAME}_DEPENDENT_LIBRARIES})
endif()
if(NOT CPACK_DEBIAN_BUILD_DEPENDS)
  set(CPACK_DEBIAN_BUILD_DEPENDS ${${UPPER_PROJECT_NAME}_BUILD_DEBS})
endif()

# Default component definition
if(NOT CPACK_COMPONENTS_ALL)
  if(RELEASE_VERSION)
    set(CPACK_COMPONENTS_ALL lib dev doc apps examples)
  else()
    set(CPACK_COMPONENTS_ALL unspecified lib dev doc apps examples)
  endif()

  set(CPACK_COMPONENT_UNSPECIFIED_DISPLAY_NAME "Unspecified")
  set(CPACK_COMPONENT_UNSPECIFIED_DESCRIPTION
    "Unspecified Component - set COMPONENT in CMake install() command")

  set(CPACK_COMPONENT_LIB_DISPLAY_NAME "${CPACK_PROJECT_NAME} Libraries")
  set(CPACK_COMPONENT_LIB_DESCRIPTION "${CPACK_PROJECT_NAME} Runtime Libraries")

  set(CPACK_COMPONENT_DEV_DISPLAY_NAME
    "${CPACK_PROJECT_NAME} Development Files")
  set(CPACK_COMPONENT_DEV_DESCRIPTION
    "Header and Library Files for ${CPACK_PROJECT_NAME} Development")
  set(CPACK_COMPONENT_DEV_DEPENDS lib)

  set(CPACK_COMPONENT_DOC_DISPLAY_NAME "${CPACK_PROJECT_NAME} Documentation")
  set(CPACK_COMPONENT_DOC_DESCRIPTION "${CPACK_PROJECT_NAME} Documentation")
  set(CPACK_COMPONENT_DOC_DEPENDS lib)

  set(CPACK_COMPONENT_APPS_DISPLAY_NAME "${CPACK_PROJECT_NAME} Applications")
  set(CPACK_COMPONENT_APPS_DESCRIPTION "${CPACK_PROJECT_NAME} Applications")
  set(CPACK_COMPONENT_APPS_DEPENDS lib)

  set(CPACK_COMPONENT_EXAMPLES_DISPLAY_NAME "${CPACK_PROJECT_NAME} Examples")
  set(CPACK_COMPONENT_EXAMPLES_DESCRIPTION
    "${CPACK_PROJECT_NAME} Example Source Code")
  set(CPACK_COMPONENT_EXAMPLES_DEPENDS dev)
elseif(CPACK_COMPONENTS_ALL STREQUAL "none")
  set(CPACK_COMPONENTS_ALL)
endif()

include(LSBInfo)

if(CMAKE_SYSTEM_NAME MATCHES "Linux")
  find_program(RPM_EXE rpmbuild)
  find_program(DEB_EXE debuild)
endif()

# Auto-package-version magic
include(Revision)
set(CMAKE_PACKAGE_VERSION "" CACHE
  STRING "Additional build version for packages")
mark_as_advanced(CMAKE_PACKAGE_VERSION)

if(GIT_REVISION)
  if(NOT PACKAGE_VERSION_REVISION STREQUAL GIT_REVISION)
    if(PACKAGE_VERSION_REVISION)
      if(CMAKE_PACKAGE_VERSION)
        math(EXPR CMAKE_PACKAGE_VERSION "${CMAKE_PACKAGE_VERSION} + 1")
      else()
        set(CMAKE_PACKAGE_VERSION "1")
      endif()
    else()
      set(CMAKE_PACKAGE_VERSION "")
    endif()
    set(CMAKE_PACKAGE_VERSION ${CMAKE_PACKAGE_VERSION} CACHE STRING
      "Additional build version for packages" FORCE)
  endif()
  set(PACKAGE_VERSION_REVISION ${GIT_REVISION} CACHE INTERNAL "" FORCE)
endif()

# Heuristics to figure out cpack generator
if(MSVC)
  set(CPACK_GENERATOR "NSIS")
  set(CPACK_NSIS_MODIFY_PATH ON)
elseif(APPLE)
  set(CPACK_GENERATOR "PackageMaker")
  set(CPACK_OSX_PACKAGE_VERSION "${${UPPER_PROJECT_NAME}_OSX_VERSION}")
elseif(LSB_DISTRIBUTOR_ID MATCHES "Ubuntu")
  set(CPACK_GENERATOR "DEB")
elseif(LSB_DISTRIBUTOR_ID MATCHES "RedHatEnterpriseServer")
  set(CPACK_GENERATOR "RPM")
elseif(DEB_EXE)
  set(CPACK_GENERATOR "DEB")
elseif(RPM_EXE)
  set(CPACK_GENERATOR "RPM")
else()
  set(CPACK_GENERATOR "TGZ")
endif()

if(CPACK_GENERATOR STREQUAL "RPM")
  set(CPACK_RPM_PACKAGE_GROUP "Development/Libraries")
  set(CPACK_RPM_PACKAGE_LICENSE ${CPACK_PACKAGE_LICENSE})
  set(CPACK_RPM_PACKAGE_RELEASE ${CMAKE_PACKAGE_VERSION})
  set(CPACK_RPM_PACKAGE_VERSION ${VERSION})
  set(CPACK_PACKAGE_FILE_NAME "${CPACK_PACKAGE_NAME}-${CPACK_PACKAGE_VERSION}.${CMAKE_SYSTEM_PROCESSOR}")
  if(NOT CPACK_RPM_POST_INSTALL_SCRIPT_FILE)
    set(CPACK_RPM_POST_INSTALL_SCRIPT_FILE "${CMAKE_CURRENT_LIST_DIR}/rpmPostInstall.sh")
  endif()
  set(CPACK_RPM_PACKAGE_OBSOLETES ${OLD_PACKAGES})
else()
  if(CMAKE_PACKAGE_VERSION)
    set(CPACK_PACKAGE_VERSION
      ${CPACK_PACKAGE_VERSION}-${CMAKE_PACKAGE_VERSION})
  endif()

  if(CPACK_GENERATOR STREQUAL "DEB")
    # dpkg requires lowercase package names
    string(TOLOWER "${CPACK_PACKAGE_NAME}" CPACK_DEBIAN_PACKAGE_NAME)

    set(CPACK_DEBIAN_PACKAGE_VERSION
      "${CPACK_PACKAGE_VERSION}~${CPACK_PACKAGE_NAME_EXTRA}${LSB_RELEASE}")
    set(CPACK_PACKAGE_FILE_NAME
      "${CPACK_PACKAGE_NAME}-${CPACK_PACKAGE_VERSION}~${CPACK_PACKAGE_NAME_EXTRA}${LSB_RELEASE}.${CMAKE_SYSTEM_PROCESSOR}")

    if(NOT CPACK_DEBIAN_PACKAGE_CONTROL_EXTRA)
      set(CPACK_DEBIAN_PACKAGE_CONTROL_EXTRA "/sbin/ldconfig")
    endif()

    if(NOT CPACK_DEBIAN_PACKAGE_MAINTAINER)
      set(CPACK_DEBIAN_PACKAGE_MAINTAINER "${CPACK_PACKAGE_CONTACT}")
    endif()

    # setup'd by Buildyard config, same as for travis CI
    if(NOT CPACK_DEBIAN_BUILD_DEPENDS AND ${UPPER_PROJECT_NAME}_BUILD_DEBS)
      set(CPACK_DEBIAN_BUILD_DEPENDS ${${UPPER_PROJECT_NAME}_BUILD_DEBS})
    endif()

    set(CPACK_DEBIAN_PACKAGE_CONFLICTS ${OLD_PACKAGES})
  endif()
endif()

set(CPACK_STRIP_FILES TRUE)
include(InstallRequiredSystemLibraries)

set(CPACK_PACKAGE_FILE_NAME_BACKUP "${CPACK_PACKAGE_FILE_NAME}")
include(CPack)
set(CPACK_PACKAGE_FILE_NAME "${CPACK_PACKAGE_FILE_NAME_BACKUP}")

include(UploadPPA)
include(MacPorts)
if(UPLOADPPA_FOUND)
  upload_ppas()
endif()
