## *#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#* portfile.cmake *#*#*#*#*#*#*#*#*#*#*#*#*#*#*# (C) 2026 DekTec
##
## vcpkg port file for DekTec's CDTAPI, a native C API for DekTec SDI, DVB-ASI and SMPTE ST 2110 interfaces.
##
## CDTAPI is BSD-3-Clause C11 that talks to the DtPcie driver itself, so this port builds it from source
## like any other port. The wrapper this replaces shipped built archives, because it linked closed DTAPI.

## +=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+
## +=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+ Download +=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=
## +=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+

vcpkg_from_github(
  OUT_SOURCE_PATH SOURCE_PATH
  REPO dektec-com/cdtapi
  REF "v${VERSION}"
  SHA512 77a20925f942c8a6aa387558b9692ef4ea09af6184002e7bd1d0a0502aabd9ac1cf4aef07e86c89777246381f5a38ac391ef2e4f90be69379bd957b78afe0e31)

## +=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+ Build +=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=
## +=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+

## The library builds a static or a shared library from one option, so the triplet's linkage chooses it.
if(VCPKG_LIBRARY_LINKAGE STREQUAL "dynamic")
  set(CDTAPI_SHARED ON)
else()
  set(CDTAPI_SHARED OFF)
endif()

## The tests and the examples are the library's own; a consumer installs neither. Warnings are not errors
## here: a customer's compiler is newer than the one the release was built with, and a warning it has
## learned since must not fail their install.
vcpkg_cmake_configure(
  SOURCE_PATH "${SOURCE_PATH}"
  OPTIONS
    -DCDTAPI_BUILD_SHARED=${CDTAPI_SHARED}
    -DCDTAPI_BUILD_TESTS=OFF
    -DCDTAPI_BUILD_EXAMPLES=OFF
    -DCDTAPI_WARNINGS_AS_ERRORS=OFF)

vcpkg_cmake_install()

## +=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+ Install +=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=
## +=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+

## find_package(cdtapi CONFIG) is how a consumer asks for it; this moves the package where vcpkg puts it.
vcpkg_cmake_config_fixup(PACKAGE_NAME cdtapi CONFIG_PATH lib/cmake/cdtapi)

vcpkg_fixup_pkgconfig()
vcpkg_copy_pdbs()

## The headers and the CMake package are installed once, for both configurations.
file(REMOVE_RECURSE
  "${CURRENT_PACKAGES_DIR}/debug/include"
  "${CURRENT_PACKAGES_DIR}/debug/share")

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")
