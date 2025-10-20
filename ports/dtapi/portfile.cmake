## *#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#* portfile.cmake *#*#*#*#*#*#*#*#*#*#*#*#*#*#*# (C) 2024 DekTec
##
## vcpkg port file for DekTec's C++ API (aka 'DTAPI').

## +=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+
## +=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+ Preconditions and configuration +=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+
## +=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+

## Warn that only static linking is supported.
vcpkg_check_linkage(ONLY_STATIC_LIBRARY )

## Init variabale for name of library source file to safe initial values.
set(LIB_NAME_BASE "DTAPI")
set(LIB_NAME_ARCH "")
set(LIB_NAME_CRT "")
set(LIB_NAME_EXT "")
set(LIB_NAME_DBG_SUFFIX "")

## +=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+
## +=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+ Download and extract files +=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=
## +=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+

## Determine which platform is targeted?
if(VCPKG_TARGET_IS_WINDOWS)

  message(STATUS "Installing DTAPI v${VERSION} for Windows.")
  
  ## Mutual exclusivity check for Windows-only features
  if ("vc17" IN_LIST FEATURES AND "vc16" IN_LIST FEATURES AND "vc15" IN_LIST FEATURES)
    message(FATAL_ERROR "Features 'vc17', 'vc16' and 'vc15' are mutually exclusive. Please specify only one.")
  endif()

  ## Step 1: Set Windows specific names and locations for DTAPI.
  
  ## x86 or x64?
  if (VCPKG_TARGET_ARCHITECTURE STREQUAL "x86")
    set(LIB_NAME_ARCH "")
  elseif (VCPKG_TARGET_ARCHITECTURE STREQUAL "x64")
    set(LIB_NAME_ARCH "64")
  else()
    message(FATAL_ERROR "Unsupported architecture: ${VCPKG_TARGET_ARCHITECTURE}")
  endif()
  
  ## Which visual studio version?
  if ("vc17" IN_LIST FEATURES)
    set(LIB_SRCDIR "vc17")
  elseif ("vc16" IN_LIST FEATURES)
    set(LIB_SRCDIR "vc16")
  elseif ("vc15" IN_LIST FEATURES)
    set(LIB_SRCDIR "vc15")
  else()
    ## No feature specified => auto detect based on platform toolset.
    if (VCPKG_PLATFORM_TOOLSET STREQUAL "v143")
      set(LIB_SRCDIR "vc17")
    elseif (VCPKG_PLATFORM_TOOLSET STREQUAL "v142")
      set(LIB_SRCDIR "vc16")
    elseif (VCPKG_PLATFORM_TOOLSET STREQUAL "v141")
      set(LIB_SRCDIR "vc15")
    else()
      ## Default to VC16 version.
      set(LIB_SRCDIR "vc16")
    endif()
  endif()
  
  ## Using dynamic or static runtimes?
  if (VCPKG_CRT_LINKAGE STREQUAL "dynamic")
    set(LIB_NAME_CRT "MD")
  else()
    set(LIB_NAME_CRT "MT")
  endif()

  set(LIB_NAME_EXT "lib")
  set(LIB_NAME_DBG_SUFFIX "d")
  
  ## Step 2: Download zip with Windows binaries.
  vcpkg_download_distfile(
    ARCHIVE
    URLS "https://dektec.com/products/SDK/DTAPI/Downloads/dtapi-v${VERSION}-windows.zip"
    FILENAME "dtapi-v${VERSION}-windows.tar.gz"
    SHA512 37F8D8F0493633D14A6AB5B67D0B728808E91CAFA4995E00556D929FF50116838128248B97B4AE1387C4BF79D49DA036C8E09FEDDD9ACE367D253E533FE7E6B0
  )

elseif(VCPKG_TARGET_IS_LINUX)

  message(STATUS "Installing DTAPI v${VERSION} for Linux.")
  
  ## Step 1: set Linux specific names and locations for DTAPI.
  
  set(LIB_SRCDIR ".")
  
  ## x86 or x64?
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
  
  ## Step 2: Download zip with Linux binaries.
  vcpkg_download_distfile(
    ARCHIVE
    URLS "https://dektec.com/products/SDK/DTAPI/Downloads/dtapi-v${VERSION}-linux.tar.gz"
    FILENAME "dtapi-v${VERSION}-linux.tar.gz"
    SHA512 B14987B37AF9BCA8D8B6F9F7387D8192B73960BD40611618E1C46801706EE5C8139BD4D52FAE435954542975C52F5B97D4514DD765A3894F375478500D63E216
  )
  
else()
  message(FATAL_ERROR "Only the Windows and Linux platforms are supported.")
endif()

## Step 3: Extract archive with DTAPI.
vcpkg_extract_source_archive_ex(OUT_SOURCE_PATH SOURCE_PATH ARCHIVE ${ARCHIVE})

## Construct full library name.
set(LIB_NAME "${LIB_NAME_BASE}${LIB_NAME_ARCH}${LIB_NAME_CRT}")
message(STATUS "Using '${LIB_SRCDIR}/${LIB_NAME}.${LIB_NAME_EXT}' as source")

## +=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+
## =+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+ Install files +=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=
## +=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+

## Install - DTAPI includes.
file(GLOB INCLUDE_FILES ${SOURCE_PATH}/include/DTAPI*.h)
foreach(INCLUDE_FILE ${INCLUDE_FILES})
  file(INSTALL
   "${INCLUDE_FILE}"
   DESTINATION ${CURRENT_PACKAGES_DIR}/include/${PORT}
  )
endforeach()

## Install - DTAPI debug library.
file(INSTALL
     "${SOURCE_PATH}/lib/${LIB_SRCDIR}/${LIB_NAME}${LIB_NAME_DBG_SUFFIX}.${LIB_NAME_EXT}"
     DESTINATION ${CURRENT_PACKAGES_DIR}/debug/lib
     RENAME "${LIB_NAME_BASE}.${LIB_NAME_EXT}"
    )

## Install - DTAPI release library.
file(INSTALL
     "${SOURCE_PATH}/lib/${LIB_SRCDIR}/${LIB_NAME}.${LIB_NAME_EXT}"
       DESTINATION ${CURRENT_PACKAGES_DIR}/lib
     RENAME "${LIB_NAME_BASE}.${LIB_NAME_EXT}"
    )
## Install - DTAPI copyright file.
file(INSTALL
   "${SOURCE_PATH}/share/copyright"
   DESTINATION ${CURRENT_PACKAGES_DIR}/share/${PORT}
  )

## Install - DTAPI cmake files library.
file(GLOB SHARE_FILES ${SOURCE_PATH}/share/*.cmake)
foreach(SHARE_FILE ${SHARE_FILES})
  file(INSTALL
  "${SHARE_FILE}"
  DESTINATION ${CURRENT_PACKAGES_DIR}/share/${PORT}
  )
endforeach()

## Rename cmake target to DTAPI::DTAPI-static when a static CRT is used.
if (VCPKG_CRT_LINKAGE STREQUAL "static")
  file(GLOB SHARE_FILES ${CURRENT_PACKAGES_DIR}/share/${PORT}/*.cmake)
  foreach(SHARE_FILE ${SHARE_FILES})
    vcpkg_replace_string("${SHARE_FILE}" "DTAPI::DTAPI" "DTAPI::DTAPI-static")
  endforeach()
endif()

## +=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+
## Check if one or more features are a part of a package installation.
## See /docs/maintainers/vcpkg_check_features.md for more details
vcpkg_check_features(OUT_FEATURE_OPTIONS FEATURE_OPTIONS
  FEATURES # <- Keyword FEATURES is required because INVERTED_FEATURES are being used
    tbb   WITH_TBB
  INVERTED_FEATURES
    tbb   ROCKSDB_IGNORE_PACKAGE_TBB
)