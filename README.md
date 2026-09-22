# DekTec's vcpkg registry

A [vcpkg registry](https://learn.microsoft.com/vcpkg/concepts/registries) holding the
ports of DekTec's libraries, for a project that manages its dependencies with vcpkg.

| Port | What it is |
|---|---|
| `cdtapi` | The C API for DekTec SDI, DVB-ASI and SMPTE ST 2110 interfaces. BSD-3-Clause, built from source. |
| `dtapi` | The C++ API for DekTec devices, as precompiled binaries. |
| `ffmpeg-dektec` | FFmpeg with DekTec's devices and the `sdi` format, on `cdtapi`. LGPL, built from source. |
| `gst-dektec` | The `dektec` GStreamer plugin for DekTec's SDI, DVB-ASI and SMPTE ST 2110 hardware. BSD-3-Clause, built from source. |

## Using it

Name this registry in `vcpkg-configuration.json`, beside your manifest:

```json
{
  "default-registry": {
    "kind": "git",
    "repository": "https://github.com/microsoft/vcpkg",
    "baseline": "<a commit of microsoft/vcpkg>"
  },
  "registries": [
    {
      "kind": "git",
      "repository": "https://github.com/dektec-com/dektec-vcpkg-registry",
      "baseline": "<a commit of this repository>",
      "packages": [ "cdtapi", "dtapi", "ffmpeg-dektec", "gst-dektec" ]
    }
  ]
}
```

and ask for what you need in `vcpkg.json`:

```json
{
  "name": "my-application",
  "version": "1.0.0",
  "dependencies": [ "cdtapi" ]
}
```

A baseline is a commit of the registry it belongs to, which fixes the versions your
build resolves; `git ls-remote https://github.com/dektec-com/dektec-vcpkg-registry HEAD`
gives the newest of this one. Naming a commit rather than a branch is what makes a build
reproducible.

`cdtapi` and `dtapi` provide a CMake package:

```cmake
find_package(cdtapi CONFIG REQUIRED)
target_link_libraries(myapp PRIVATE cdtapi::cdtapi)
```

## What the ports give you

**`cdtapi`** is built from the sources at
[github.com/dektec-com/cdtapi](https://github.com/dektec-com/cdtapi), from the tag of
the version asked for, so the triplet decides what comes out: `x64-windows` gives the
DLL, `x64-windows-static` and `x64-linux` the static library. It needs nothing else
installed. Supported triplets are the x64 ones of Windows and Linux.

**`dtapi`** installs precompiled binaries. On Windows the features `vc15`, `vc16` and
`vc17` choose which Visual Studio version's binaries are installed; pick one. They are
mutually exclusive, and without a feature the port follows the platform toolset.

**`ffmpeg-dektec`** is vcpkg's own `ffmpeg` port with DekTec's fork of FFmpeg as its
source, [github.com/dektec-com/ffmpeg-dektec](https://github.com/dektec-com/ffmpeg-dektec),
built with `--enable-libcdtapi`: the `dektec` input and output device and the `sdi`
format come with FFmpeg's libraries, and its features are those of the `ffmpeg` port.
It installs the same libraries and headers as that port and cannot be installed beside
it. The fork's repository is private for now: vcpkg fetches it over SSH, so the port
installs only for someone whose `git` can reach `git@github.com:dektec-com/ffmpeg-dektec`.

**`gst-dektec`** is built from the sources at
[github.com/dektec-com/gst-dektec](https://github.com/dektec-com/gst-dektec), from the
tag of the version asked for, with the DTAPI backend. It installs the plugin,
`lib/gstreamer-1.0/gstdektec.dll` or `libgstdektec.so`, and the `dt-probe` tool under
`tools/gst-dektec`; point `GST_PLUGIN_PATH` at that `lib/gstreamer-1.0`. The plugin is
loaded by the GStreamer installed on the system, so it is built against that one and not
against vcpkg's `gstreamer` port: GStreamer 1.24 or newer with its development files has to
be installed first, the official MSVC SDK on Windows (found through
`GSTREAMER_1_0_ROOT_MSVC_X86_64`, or in `C:\gstreamer\1.0\msvc_x86_64`) and
`libgstreamer1.0-dev` and `libgstreamer-plugins-base1.0-dev` on Linux. DTAPI and the other
libraries are linked into the plugin, so on Windows use a static triplet,
`x64-windows-static-md`; with a dynamic one the plugin needs their DLLs beside it. Like
`ffmpeg-dektec`, the repository is private for now and vcpkg fetches it over SSH.

## Keeping it up to date (DekTec)

`publish.sh` publishes a new version of a port:

    ./publish.sh cdtapi 6.13.4 "what changed"
    ./publish.sh ffmpeg-dektec 9.0.2 "what changed" --tag n9.0.2-dektec2
    ./publish.sh dtapi 6.13.1 "what changed"
    ./publish.sh gst-dektec 0.2.0 "what changed" --tag v0.2.0

It works out how the portfile fetches its source and follows it: for
`vcpkg_from_github` it downloads the tarball of the tag and writes its SHA-512 down, for
`vcpkg_from_git` it asks the remote what the tag stands for and writes that commit,
counting the port version up since the same software is built the same way, and for
`vcpkg_download_distfile` it hashes every URL of the new version. Then it writes the
version into the manifest and makes the two commits a new version takes, because
`x-add-version` reads the port from the repository's history:

    vcpkg format-manifest ports/<port>/vcpkg.json
    git add --all && git commit -m "<port> <version>: what changed"

    vcpkg x-add-version <port> --overlay-ports=./ports \
        --x-builtin-registry-versions-dir=./versions/ --x-builtin-ports-root=./ports
    git add --all && git commit -m "The registry's baseline for <port> is <version>"

It does not push. Read the two commits, and build the port from the working copy and use
it, on every platform it supports:

    vcpkg install <port>:x64-windows --overlay-ports=./ports
    vcpkg install <port>:x64-linux --overlay-ports=./ports

The source has to be published before its hash means anything: for `cdtapi`,
`ffmpeg-dektec` and `gst-dektec` that is the tag on GitHub, and a tag that moves afterwards invalidates
the hash; for `dtapi` it is the archive of binaries on dektec.com, which is put there by
hand, so a new DTAPI goes onto the website first and into the registry after. The
`cdtapi` tag's own Release names the hash as well, which is the same number `publish.sh`
computes.
