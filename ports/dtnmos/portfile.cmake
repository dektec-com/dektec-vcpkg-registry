## *#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#* portfile.cmake *#*#*#*#*#*#*#*#*#*#*#*#*#*#*# (C) 2026 DekTec
##
## vcpkg port file for dtnmos, a C library for the SDP of SMPTE ST 2110 flows and for NMOS IS-04 and IS-05.
##
## dtnmos is BSD-3-Clause C11 without dependencies of its own. Its HTTP client on libcurl and the server of
## its node on civetweb are optional, and are the features curl and server.

## +=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+
## +=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+ Download +=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=
## +=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+

vcpkg_from_github(
  OUT_SOURCE_PATH SOURCE_PATH
  REPO dektec-com/dtnmos
  REF "v${VERSION}"
  SHA512 6be60da790af5299063312be119c474ada2b134ca49219a94b7f204e48e86a6a0c2df8ed2523be03d5e3960f2c4073679302ac050a3853f8012c86c752b5b978)

## +=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+ Build +=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=
## +=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+

vcpkg_check_features(OUT_FEATURE_OPTIONS FEATURE_OPTIONS
  FEATURES
    curl   DTNMOS_WITH_CURL
    server DTNMOS_WITH_SERVER)

## The library builds a static or a shared library from BUILD_SHARED_LIBS, which vcpkg sets from the triplet's
## linkage. The tests and the examples are the library's own; a consumer does not install them. Warnings are
## not errors here: a customer's compiler is newer than the one the release was built with, and a warning it
## has learned since must not fail their install.
vcpkg_cmake_configure(
  SOURCE_PATH "${SOURCE_PATH}"
  OPTIONS
    ${FEATURE_OPTIONS}
    -DDTNMOS_BUILD_EXAMPLES=OFF
    -DDTNMOS_BUILD_TESTS=OFF
    -DDTNMOS_INSTALL=ON
    -DDTNMOS_WARNINGS_AS_ERRORS=OFF)

vcpkg_cmake_install()

## +=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+ Install +=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=
## +=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+

## find_package(dtnmos CONFIG) is how a consumer asks for it; this moves the package where vcpkg puts it.
vcpkg_cmake_config_fixup(PACKAGE_NAME dtnmos CONFIG_PATH lib/cmake/dtnmos)

vcpkg_fixup_pkgconfig()
vcpkg_copy_pdbs()

## The headers and the CMake package are installed once, for both configurations.
file(REMOVE_RECURSE
  "${CURRENT_PACKAGES_DIR}/debug/include"
  "${CURRENT_PACKAGES_DIR}/debug/share")

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")
