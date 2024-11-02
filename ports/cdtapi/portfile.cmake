# Warn that only static linking is supported
vcpkg_check_linkage(ONLY_STATIC_LIBRARY )

# CDTAPI version used by this port file.
set(CDTAPI_VERSION 1.1.0)

# Init variabale for name of library source file to safe initial values.
set(LIB_NAME_BASE "cdtapi")
set(LIB_NAME_ARCH "")
set(LIB_NAME_CRT "")
set(LIB_NAME_EXT "")
set(LIB_NAME_DBG_SUFFIX "")

# Determine which platform is targetted
if(VCPKG_TARGET_IS_WINDOWS)
  message(STATUS "Installing CDTAPI for Windows.")
  
  # Mutual exclusivity check for Windows-only features
  if ("vc17" IN_LIST FEATURES AND "vc16" IN_LIST FEATURES AND "vc15" IN_LIST FEATURES)
    message(FATAL_ERROR "Features 'vc17', 'vc16' and 'vc15' are mutually exclusive. Please specify only one.")
  endif()

  # Step 1: set Windows specific names and locations for CDTAPI
  
  #x86 or x64
  if (VCPKG_TARGET_ARCHITECTURE STREQUAL "x86")
    set(LIB_NAME_ARCH "")
  elseif (VCPKG_TARGET_ARCHITECTURE STREQUAL "x64")
    set(LIB_NAME_ARCH "64")
  else()
    message(FATAL_ERROR "Unsupported architecture: ${VCPKG_TARGET_ARCHITECTURE}")
  endif()
  
  # Which visual studio verions?
  if ("vc17" IN_LIST FEATURES)
    set(LIB_SRCDIR "vc17")
  elseif ("vc16" IN_LIST FEATURES)
    set(LIB_SRCDIR "vc16")
  elseif ("vc15" IN_LIST FEATURES)
    set(LIB_SRCDIR "vc15")
  else()
    # No feature specified => auto detect based on platform toolset.
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
  endif()
  
  # Using dynamic or static runtimes?
  if (VCPKG_CRT_LINKAGE STREQUAL "dynamic")
    set(LIB_NAME_CRT "MD")
  else()
    set(LIB_NAME_CRT "MT")
  endif()

  set(LIB_NAME_EXT "lib")
  set(LIB_NAME_DBG_SUFFIX "d")
  
  #Step 2: cdtapi from github.
  vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO dektec-projects/cdtapi
    REF "v${CDTAPI_VERSION}"
    SHA512 2cadbf73c80990f36018805ad76c7b7fbdb506958d13f96f26e6fcef8717e789f2ac70be769676e3562d17115d45b32835bba84e302f26f25f872dddce200e65
)

elseif(VCPKG_TARGET_IS_LINUX)
  message(STATUS "Installing CDTAPI for Linux.")
  
  # Step 1: set Linux specific names and locations for cdtapi.
  
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
  
else()
  message(FATAL_ERROR "Only the Windows and Linux platforms are supported.")
endif()

# Construct full library name
set(LIB_NAME "${LIB_NAME_BASE}${LIB_NAME_ARCH}${LIB_NAME_CRT}")
message(STATUS "Using '${LIB_SRCDIR}/${LIB_NAME}.${LIB_NAME_EXT}' as source")

## Configure cmake
vcpkg_cmake_configure(SOURCE_PATH ${SOURCE_PATH} OPTIONS -DVCPKG_BUILD=ON)
## Let cmake install our targets
vcpkg_cmake_install()
## Moves cmake files from debug/share to /share
vcpkg_cmake_config_fixup()
## Deletes the duplicate include directory from the debug/include installation to prevent overlap.
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")

## install license/copyright file
vcpkg_install_copyright(FILE_LIST ${SOURCE_PATH}/license.md)

############################################################
# Check if one or more features are a part of a package installation.
# See /docs/maintainers/vcpkg_check_features.md for more details
vcpkg_check_features(OUT_FEATURE_OPTIONS FEATURE_OPTIONS
  FEATURES # <- Keyword FEATURES is required because INVERTED_FEATURES are being used
    tbb   WITH_TBB
  INVERTED_FEATURES
    tbb   ROCKSDB_IGNORE_PACKAGE_TBB
)