# Warn that only static linking is supported
vcpkg_check_linkage(ONLY_STATIC_LIBRARY )

# Init variabale for name of library source file to safe initial 
set(LIB_NAME_BASE "DTAPI")
set(LIB_NAME_ARCH "")
set(LIB_NAME_CRT "")
set(LIB_NAME_EXT "")

# Determine which platform is targetted
if(VCPKG_TARGET_IS_WINDOWS)
  message(STATUS "Installing DTAPI for Windows.")
  
  # Step 1: set Windows specific names and locations for DTAPI
  
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
    # Default to VC16 version.
    set(LIB_SRCDIR "vc16")
  endif()
  
  # Using dynamic or static runtimes?
  if (VCPKG_CRT_LINKAGE STREQUAL "dynamic")
    set(LIB_NAME_CRT "MD")
  else()
    set(LIB_NAME_CRT "MT")
  endif()

  set(LIB_NAME_EXT "lib")
  
  #Step 2: download zip with Windows binaries.
  vcpkg_download_distfile(
    ARCHIVE
    URLS "https://dektec.com/products/SDK/DTAPI/Downloads/dtapi-v${DTAPI_VERSION}-windows.zip"
    FILENAME "dtapi-v${DTAPI_VERSION}-windows.tar.gz"
    SHA512 3ab685bab339aa4a925a146c4843530ed037a79f35974b2e2fd5b88f8673868355703256e7104d4ab7dca553c3f87b1f35dcb3a7a28e0744dd9cc34f4ebe5690
  )

elseif(VCPKG_TARGET_IS_LINUX)
  message(STATUS "Installing DTAPI for Linux.")
  
  # Step 1: set Linux specific names and locations for DTAPI.
  
  set(LIB_SRCDIR ".")
  
  #x86 or x64
  if (VCPKG_TARGET_ARCHITECTURE STREQUAL "x86")
    set(LIB_NAME_ARCH "")
  elseif (VCPKG_TARGET_ARCHITECTURE STREQUAL "x64")
    set(LIB_NAME_ARCH "64")
  else()
    message(FATAL_ERROR "Unsupported architecture: ${VCPKG_TARGET_ARCHITECTURE}")
  endif()
  
  set(LIB_NAME_CRT "")
  set(LIB_NAME_EXT "o")
  
  #Step 2: download zip with Linux binaries.
  vcpkg_download_distfile(
    ARCHIVE
    URLS "https://dektec.com/products/SDK/DTAPI/Downloads/dtapi-v${DTAPI_VERSION}-linux.tar.gz"
    FILENAME "dtapi-v${DTAPI_VERSION}-linux.tar.gz"
    SHA512 EE2244F9A85BADE0034E2792A0C314B7A02B9E48724DA72B676FC84021A361536C46A216037B263A19202347E3D1111B4226FF3387CF66899FEB24DBA8C3BFF6
  )
  
else()
  message(FATAL_ERROR "Only the Windows and Linux platforms are supported.")
endif()

# Step 3: extract archive with DTAPI
vcpkg_extract_source_archive_ex(
    OUT_SOURCE_PATH SOURCE_PATH ARCHIVE ${ARCHIVE}
  )

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