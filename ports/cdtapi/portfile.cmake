## *#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#* portfile.cmake *#*#*#*#*#*#*#*#*#*#*#*#*#*#*# (C) 2024 DekTec
##
## vcpkg port file for DekTec's CDTAPI, a C-wrapper for the C++ DekTec (aka 'DTAPI').

## +=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+
## +=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+ Preconditions and configuration +=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+
## +=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+

## Warn that only static linking is supported.
vcpkg_check_linkage(ONLY_STATIC_LIBRARY)

## Determine which platform is targeted.
if(VCPKG_TARGET_IS_WINDOWS)

  message(STATUS "Installing CDTAPI v${VERSION} for Windows.")
  
  ## Mutual exclusivity check for Windows-only features.
  if ("vc17" IN_LIST FEATURES AND "vc16" IN_LIST FEATURES AND "vc15" IN_LIST FEATURES)
    message(FATAL_ERROR "Features 'vc17', 'vc16' and 'vc15' are mutually exclusive. Please specify only one.")
  endif()

elseif(VCPKG_TARGET_IS_LINUX)
  message(STATUS "Installing CDTAPI v${VERSION} for Linux.")
else()
  message(FATAL_ERROR "Only the Windows and Linux platforms are supported.")
endif()

## +=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+
## =+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+ Download and install +=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+
## +=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+

## Step 1: Get 'cdtapi' from github
vcpkg_from_github(
  OUT_SOURCE_PATH SOURCE_PATH
  REPO dektec-projects/cdtapi
  REF "v${VERSION}"
  SHA512 2cadbf73c80990f36018805ad76c7b7fbdb506958d13f96f26e6fcef8717e789f2ac70be769676e3562d17115d45b32835bba84e302f26f25f872dddce200e65)

## Step 2: Configure cmake. Enable the 'VCPKG_BUILD' option, so that the package knowns it is about to be 
##         build in a vcpkg context.
vcpkg_cmake_configure(SOURCE_PATH ${SOURCE_PATH} OPTIONS -DVCPKG_BUILD=ON)

## Step 3: Let cmake build/install our targets.
vcpkg_cmake_install()

## Step 4: Install license/copyright file.
vcpkg_install_copyright(FILE_LIST ${SOURCE_PATH}/license.md)

## Step 5: Fix issues with debug cmake files ending up in /debug/share instead of /share.
vcpkg_cmake_config_fixup()

## Step 6: Delete duplicate include directory, that ends up in debug/include, to prevent overlap.
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")

## +=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+
## Check if one or more features are a part of a package installation. 
## See /docs/maintainers/vcpkg_check_features.md for more details
vcpkg_check_features(OUT_FEATURE_OPTIONS FEATURE_OPTIONS
  FEATURES # <- Keyword FEATURES is required because INVERTED_FEATURES are being used
    tbb   WITH_TBB
  INVERTED_FEATURES
    tbb   ROCKSDB_IGNORE_PACKAGE_TBB
)