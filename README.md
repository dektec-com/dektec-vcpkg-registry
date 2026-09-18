# DekTec's vcpkg registry

A [vcpkg registry](https://learn.microsoft.com/vcpkg/concepts/registries) holding the
ports of DekTec's libraries, for a project that manages its dependencies with vcpkg.

| Port | What it is |
|---|---|
| `cdtapi` | The C API for DekTec SDI and SMPTE ST 2110 interfaces. BSD-3-Clause, built from source. |
| `dtapi` | The C++ API for DekTec devices, as precompiled binaries. |

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
      "packages": [ "cdtapi", "dtapi" ]
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

Both ports provide a CMake package:

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

## Keeping it up to date (DekTec)

A new version of a port is added in two commits, because `x-add-version` reads the port
from the repository's history:

    vcpkg format-manifest ports/<port>/vcpkg.json
    git add --all && git commit -m "<port> <version>: what changed"

    vcpkg x-add-version <port> --overlay-ports=./ports \
        --x-builtin-registry-versions-dir=./versions/ --x-builtin-ports-root=./ports
    git add --all && git commit -m "The registry's baseline for <port> is <version>"
    git push

`update.bat <port> <message>` does the same in one go and pushes.

Before committing, build the port from a working copy and use it, on every platform it
supports:

    vcpkg install <port>:x64-windows --overlay-ports=./ports

`vcpkg_from_github` wants the SHA512 of the release's tarball. Put `SHA512 0` in the
portfile and run the install once: the download fails and says which hash to write down.
The tag has to exist on GitHub before that hash means anything, and a tag that moves
afterwards invalidates it.
