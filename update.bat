vcpkg format-manifest ports\%1\vcpkg.json
git add --all
git commit -m %2
vcpkg x-add-version %1 --overlay-ports=./ports --x-builtin-registry-versions-dir=./versions/ --x-builtin-ports-root=./ports
git add --all
git commit -m "update"
git push
git rev-parse HEAD