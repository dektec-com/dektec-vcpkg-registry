# Warn that only static linking is supported
vcpkg_check_linkage(ONLY_STATIC_LIBRARY )

# DTAPI version used by this port file.
set(DTAPI_VERSION 6.6.0)

# Init variabale for name of library source file to safe initial values.
set(LIB_NAME_BASE "DTAPI")
set(LIB_NAME_ARCH "")
set(LIB_NAME_CRT "")
set(LIB_NAME_EXT "")
set(LIB_NAME_DBG_SUFFIX "")

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
  set(LIB_NAME_DBG_SUFFIX "d")
  
  #Step 2: download zip with Windows binaries.
  vcpkg_download_distfile(
    ARCHIVE
    URLS "https://dektec.com/products/SDK/DTAPI/Downloads/dtapi-v${DTAPI_VERSION}-windows.zip"
    FILENAME "dtapi-v${DTAPI_VERSION}-windows.tar.gz"
    SHA512 8F9ADA0BE3955FDC0A60882B8B76E48B3123691B5D391A9026F43309FE4919E8F1A67F22D7619742A614276FA13C1388D757E32EA4E22788D8DCB63BFC5ABAEC
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
  set(LIB_NAME_DBG_SUFFIX "")
  
  #Step 2: download zip with Linux binaries.
  vcpkg_download_distfile(
    ARCHIVE
    URLS "https://dektec.com/products/SDK/DTAPI/Downloads/dtapi-v${DTAPI_VERSION}-linux.tar.gz"
    FILENAME "dtapi-v${DTAPI_VERSION}-linux.tar.gz"
    SHA512 2213FDAC1E9AECD123F3E3BFF6B4AC7590569E9E09F6567A446E686A3E313661A762BFF59463F62035B20D165B29D3BB21437087AB990D78206EF62D82D80688
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
     "${SOURCE_PATH}/lib/${LIB_SRCDIR}/${LIB_NAME}${LIB_NAME_DBG_SUFFIX}.${LIB_NAME_EXT}"
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