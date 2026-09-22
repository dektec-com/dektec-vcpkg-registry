## *#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#* portfile.cmake *#*#*#*#*#*#*#*#*#*#*#*#*#*#*# (C) 2026 DekTec
##
## vcpkg port file for gst-dektec, the GStreamer plugin for DekTec SDI, DVB-ASI and SMPTE ST 2110 hardware.
##
## The plugin is a module that the GStreamer on the system loads, so it is built against that GStreamer and
## not against vcpkg's: the official MSVC SDK on Windows, the distribution's packages on Linux. DTAPI and the
## other libraries it uses are linked into it, which is why a static triplet suits it best.

## +=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+
## +=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+ Download +=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=
## +=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+

## The repository at the release FETCH_REF names, private for now: git fetches it over SSH with the user's own
## access to it.
vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL git@github.com:dektec-com/gst-dektec.git
    REF f7cc1bd0bba3ee9e5113343e78b31230b9932519
    FETCH_REF v0.1.0
    HEAD_REF main
)

## +=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+ Build +=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=
## +=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+

## On Windows the project finds the MSVC SDK through GSTREAMER_1_0_ROOT_MSVC_X86_64, which vcpkg's clean
## environment leaves out. It is looked up where the SDK's installer and the project's setup put it, and then
## in the SDK's default location.
if(VCPKG_TARGET_IS_WINDOWS)
  set(GST_ROOT "$ENV{GSTREAMER_1_0_ROOT_MSVC_X86_64}")
  if(NOT GST_ROOT)
    cmake_host_system_information(RESULT GST_ROOT QUERY WINDOWS_REGISTRY "HKCU/Environment"
      VALUE GSTREAMER_1_0_ROOT_MSVC_X86_64)
  endif()
  if(NOT GST_ROOT)
    cmake_host_system_information(RESULT GST_ROOT QUERY WINDOWS_REGISTRY
      "HKLM/SYSTEM/CurrentControlSet/Control/Session Manager/Environment" VALUE GSTREAMER_1_0_ROOT_MSVC_X86_64)
  endif()
  if(NOT GST_ROOT AND EXISTS "C:/gstreamer/1.0/msvc_x86_64")
    set(GST_ROOT "C:/gstreamer/1.0/msvc_x86_64")
  endif()
  if(NOT GST_ROOT OR NOT EXISTS "${GST_ROOT}/lib/pkgconfig/gstreamer-1.0.pc")
    message(FATAL_ERROR "gst-dektec needs the GStreamer MSVC SDK, 1.24 or newer, with its development files "
      "(the 'devel' installer from gstreamer.freedesktop.org). Set GSTREAMER_1_0_ROOT_MSVC_X86_64 to where it is "
      "installed.")
  endif()
  set(ENV{GSTREAMER_1_0_ROOT_MSVC_X86_64} "${GST_ROOT}")
  message(STATUS "GStreamer MSVC SDK: ${GST_ROOT}")
endif()

## The tests are the project's own; a consumer installs only the plugin. Warnings are not errors here: a
## customer's compiler is newer than the one the release was built with, and a warning it has learned since
## must not fail their install.
vcpkg_cmake_configure(
  SOURCE_PATH "${SOURCE_PATH}"
  OPTIONS
    -DDTGST_WITH_DTAPI=ON
    -DDTGST_BUILD_PLUGIN=ON
    -DDTGST_BUILD_TESTS=OFF
    -DDTGST_WARNINGS_AS_ERRORS=OFF)

vcpkg_cmake_install()

## +=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+ Install +=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=
## +=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+

## The plugin is lib/gstreamer-1.0/gstdektec.dll or libgstdektec.so, where GStreamer keeps its plugins, and
## it is a module whatever the triplet's linkage: there are no headers and no import library to go with it.
set(VCPKG_POLICY_EMPTY_INCLUDE_FOLDER enabled)
set(VCPKG_POLICY_ALLOW_DLLS_IN_LIB enabled)
set(VCPKG_POLICY_DLLS_IN_STATIC_LIBRARY enabled)
set(VCPKG_POLICY_DLLS_WITHOUT_LIBS enabled)
set(VCPKG_POLICY_DLLS_WITHOUT_EXPORTS enabled)

## dt-probe reports the devices and the backends the plugin sees; it goes where vcpkg keeps tools.
vcpkg_copy_tools(TOOL_NAMES dt-probe AUTO_CLEAN)

## The licence texts of the libraries linked into the plugin go with its own, in the copyright file.
file(REMOVE "${CURRENT_PACKAGES_DIR}/THIRD-PARTY-NOTICES" "${CURRENT_PACKAGES_DIR}/debug/THIRD-PARTY-NOTICES")

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE" "${SOURCE_PATH}/THIRD-PARTY-NOTICES")
