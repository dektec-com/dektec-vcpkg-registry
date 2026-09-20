#!/usr/bin/env bash
# #*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#* publish.sh *#*#*#*#*#*#*#*#*#*#*# (C) 2026 DekTec
#
# The registry - Publishes a new version of a port
#
# A new version takes two commits, because vcpkg's x-add-version reads the port from the
# repository's history, and it takes a source reference that no one can guess: the
# SHA-512 of a release tarball, or the commit a tag stands for. This does all of it:
#
#     publish.sh cdtapi 6.13.3 "what changed"
#     publish.sh ffmpeg-dektec 9.0.2 "what changed" --tag n9.0.2-dektec2
#     publish.sh dtapi 6.13.1 "what changed"
#
# It works out what the port fetches and follows it:
#
#   vcpkg_from_github       downloads the tarball of the tag v<version> and writes its
#                           SHA-512 into the portfile
#   vcpkg_from_git          asks the remote what the tag stands for and writes that
#                           commit and the tag into the portfile; the version stays and
#                           the port version counts up, since the source is the same
#                           software built the same way
#   vcpkg_download_distfile downloads every URL of the new version and writes each
#                           SHA-512 back in the order they appear
#
# Then it formats the manifest, commits the port, runs x-add-version for the versions
# database and the baseline, and commits that. It does not push: look at the two commits
# first, and build the port from the working copy on every platform it supports.
#
# Needs vcpkg on the path, and git and curl.

set -euo pipefail

Root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$Root"

Usage()
{
    echo "Usage: publish.sh <port> <version> <what changed> [--tag <tag>] [--port-version <n>]"
    exit 2
}

[ $# -ge 3 ] || Usage
Port="$1"
Version="$2"
What="$3"
shift 3

Tag=""
PortVersion=""
while [ $# -gt 0 ]; do
    case "$1" in
    --tag) Tag="${2:-}"; shift 2 ;;
    --port-version) PortVersion="${2:-}"; shift 2 ;;
    *) Usage ;;
    esac
done

Manifest="ports/$Port/vcpkg.json"
Portfile="ports/$Port/portfile.cmake"
[ -f "$Manifest" ] && [ -f "$Portfile" ] || { echo "No such port: $Port"; exit 1; }
command -v vcpkg > /dev/null || { echo "vcpkg is not on the path"; exit 1; }
[ -z "$(git status --porcelain)" ] || { echo "The working copy has changes"; exit 1; }

# .-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.- Helpers -.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.

# The SHA-512 of what a URL serves, in the case the portfiles use.
HashOf()
{
    local Url="$1"
    local Temp
    Temp="$(mktemp)"
    curl -sSLf "$Url" -o "$Temp"
    sha512sum "$Temp" | cut -d' ' -f1
    rm -f "$Temp"
}

# Replaces the nth SHA512 line of the portfile, counting from 1.
SetHash()
{
    local Index="$1"
    local Hash="$2"
    awk -v want="$Index" -v hash="$Hash" '
        /SHA512 [0-9a-fA-F]+/ {
            seen++
            if (seen == want) {
                sub(/SHA512 [0-9a-fA-F]+/, "SHA512 " hash)
            }
        }
        { print }' "$Portfile" > "$Portfile.new"
    mv "$Portfile.new" "$Portfile"
}

# The value of a field of the manifest, as a string.
Field()
{
    sed -n "s/^ *\"$1\": *\"\{0,1\}\([^\",]*\)\"\{0,1\},\{0,1\} *$/\1/p" "$Manifest" | head -1
}

# +=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+= The source +=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+

if grep -q "vcpkg_from_github" "$Portfile"; then
    Repo="$(sed -n 's/^ *REPO \(.*\)$/\1/p' "$Portfile" | head -1)"
    Ref="${Tag:-v$Version}"
    echo "$Port: the tarball of $Repo at $Ref"
    Hash="$(HashOf "https://github.com/$Repo/archive/refs/tags/$Ref.tar.gz")"
    echo "  SHA512 $Hash"
    SetHash 1 "$Hash"

elif grep -q "vcpkg_from_git" "$Portfile"; then
    [ -n "$Tag" ] || { echo "This port fetches a tag: give --tag"; exit 1; }
    Url="$(sed -n 's/^ *URL \(.*\)$/\1/p' "$Portfile" | head -1)"
    Commit="$(git ls-remote "$Url" "refs/tags/$Tag^{}" | cut -f1)"
    [ -n "$Commit" ] || Commit="$(git ls-remote "$Url" "refs/tags/$Tag" | cut -f1)"
    [ -n "$Commit" ] || { echo "No such tag at $Url: $Tag"; exit 1; }
    echo "$Port: $Tag is $Commit"
    sed -i "s|^\( *REF \).*$|\1$Commit|; s|^\( *FETCH_REF \).*$|\1$Tag|" "$Portfile"
    sed -i "s|n[0-9][0-9.]*-dektec[0-9]*|$Tag|g" "$Portfile"

elif grep -q "vcpkg_download_distfile" "$Portfile"; then
    echo "$Port: the files of version $Version"
    Index=0
    while read -r Url; do
        Index=$((Index + 1))
        Expanded="${Url//\$\{VERSION\}/$Version}"
        Expanded="${Expanded//\"/}"
        echo "  $Expanded"
        Hash="$(HashOf "$Expanded")"
        echo "    SHA512 $Hash"
        SetHash "$Index" "$Hash"
    done < <(sed -n 's/^ *URLS \(.*\)$/\1/p' "$Portfile")
    [ "$Index" -gt 0 ] || { echo "No URLS in the portfile"; exit 1; }

else
    echo "The portfile fetches in a way this script does not know"
    exit 1
fi

# +=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+= The manifest +=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+

Old="$(Field version)"
OldPortVersion="$(Field port-version)"
: "${OldPortVersion:=0}"

if [ "$Old" = "$Version" ] && [ -z "$PortVersion" ]; then
    # The same version from a different source, as a new release of the fork is: the
    # port version counts up.
    PortVersion=$((OldPortVersion + 1))
fi

sed -i "s|^\( *\"version\": *\"\)[^\"]*\(\".*\)$|\1$Version\2|" "$Manifest"
if [ -n "$PortVersion" ]; then
    if grep -q '"port-version"' "$Manifest"; then
        sed -i "s|^\( *\"port-version\": *\)[0-9]*\(.*\)$|\1$PortVersion\2|" "$Manifest"
    else
        sed -i "s|^\( *\"version\": *\"$Version\",\)$|\1\n  \"port-version\": $PortVersion,|" \
            "$Manifest"
    fi
fi

Shown="$Version"
[ -n "$PortVersion" ] && [ "$PortVersion" != "0" ] && Shown="$Version#$PortVersion"
echo "$Port is now $Shown"

vcpkg format-manifest "$Manifest"
git add --all
git commit -q -m "$Port $Shown: $What"

# +=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+= The version database +=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+
#
# x-add-version reads the port from the commit just made and writes its git-tree, the
# version and the baseline, which is why this is a second commit.

vcpkg x-add-version "$Port" --overlay-ports=./ports \
    --x-builtin-registry-versions-dir=./versions/ --x-builtin-ports-root=./ports
git add --all
git commit -q -m "The registry's baseline for $Port is $Shown"

echo
git --no-pager log --oneline -2
echo
echo "Build it before pushing:"
echo "    vcpkg install $Port:x64-windows --overlay-ports=./ports"
echo "    vcpkg install $Port:x64-linux --overlay-ports=./ports"
