# Determine which platform is targetted
if(VCPKG_TARGET_IS_WINDOWS)
  message(STATUS "Installing DTAPI for Windows.")
  
  #Step 1: download zip with Windows binaries
  vcpkg_download_distfile(
    ARCHIVE
    URLS "https://dektec.com/products/SDK/DTAPI/Downloads/dtapi-v6.6.0-windows.zip"
    FILENAME "dtapi-6.6.0-windows.tar.gz"
    SHA512 0
  )
  
  # Step 2: extract archive with DTAPI
  vcpkg_extract_source_archive_ex(
        OUT_SOURCE_PATH SOURCE_PATH ARCHIVE ${ARCHIVE}
  )
  # Init variabale for name of library source file to safe initial 
  set(LIB_NAME_BASE "DTAPI")
  set(LIB_NAME_ARCH "")
  set(LIB_NAME_CRT "")
  set(LIB_NAME_EXT "")

  #x86 or x64
  if (VCPKG_TARGET_ARCHITECTURE STREQUAL "x86")
    set(LIB_NAME_ARCH "")
  elseif (VCPKG_TARGET_ARCHITECTURE STREQUAL "x64")
    set(LIB_NAME_ARCH "64")
  else()
    message(FATAL_ERROR "Unsupported architecture: ${VCPKG_TARGET_ARCHITECTURE}")
  endif()
  
  # Which visual studio verions?
  if (VCPKG_PLATFORM_TOOLSET STREQUAL "v143")
    set(LIB_SRCDIR "vc17")
  elseif (VCPKG_PLATFORM_TOOLSET STREQUAL "v142")
    set(LIB_SRCDIR "vc16")
  elseif (VCPKG_PLATFORM_TOOLSET STREQUAL "v141")
    set(LIB_SRCDIR "vc15")
  else()
    # Default to VC16 version
    set(LIB_SRCDIR "vc16")
  endif()
  
  # Using dynamic or static runtimes
  if (VCPKG_CRT_LINKAGE STREQUAL "dynamic")
    set(LIB_NAME_CRT "MD")
  else()
    set(LIB_NAME_CRT "MT")
  endif()

  set(LIB_NAME_EXT "lib")

elseif(VCPKG_TARGET_IS_LINUX)
  message(STATUS "Installing DTAPI for Windows.")
else()
  message(FATAL_ERROR "Only the Windows and Linux platforms are supported.")
endif()

# Construct full library name
set(LIB_NAME "${LIB_NAME_BASE}${LIB_NAME_ARCH}${LIB_NAME_CRT}")
message(STATUS "Using '${LIB_SRCDIR}/${LIB_NAME}.${LIB_NAME_EXT}' as source")

##############################################################################################################
#                                                                                                            #
# Install files                                                                                              #
#                                                                                                            #
##############################################################################################################

# Install - include file
file(GLOB INCLUDE_FILES ${SOURCE_PATH}/include/*.h)
foreach(INCLUDE_FILE ${INCLUDE_FILES})
  file(INSTALL
   "${INCLUDE_FILE}"
   DESTINATION ${CURRENT_PACKAGES_DIR}/include/${PORT}
  )
endforeach()

# Install - debug library
file(INSTALL
     "${SOURCE_PATH}/lib/${LIB_SRCDIR}/${LIB_NAME}d.${LIB_NAME_EXT}"
       DESTINATION ${CURRENT_PACKAGES_DIR}/debug/lib
     RENAME "${LIB_NAME_BASE}.${LIB_NAME_EXT}"
    ) 
# Install - release library
file(INSTALL
     "${SOURCE_PATH}/lib/${LIB_SRCDIR}/${LIB_NAME}.${LIB_NAME_EXT}"
       DESTINATION ${CURRENT_PACKAGES_DIR}/lib
     RENAME "${LIB_NAME_BASE}.${LIB_NAME_EXT}"
    )

# Install - copyright file
file(INSTALL
     "${SOURCE_PATH}/share/copyright"
     DESTINATION ${CURRENT_PACKAGES_DIR}/share/${PORT}
    )
  
## Install cmake files
file(GLOB SHARE_FILES ${SOURCE_PATH}/share/*.cmake)
foreach(SHARE_FILE ${SHARE_FILES})
  file(INSTALL
  "${SHARE_FILE}"
  DESTINATION ${CURRENT_PACKAGES_DIR}/share/${PORT}
  )
endforeach()