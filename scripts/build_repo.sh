#!/usr/bin/env bash
# Собирает статический Cydia/APT-репозиторий.
# Использование: scripts/build_repo.sh <папка с .deb> <выходная папка>
set -euo pipefail

DEBS_DIR="$1"
OUT="$2"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

rm -rf "$OUT"
mkdir -p "$OUT/debs"
cp "$DEBS_DIR"/*.deb "$OUT/debs/"
cp "$ROOT"/repo/* "$OUT/"

cd "$OUT"
dpkg-scanpackages -m debs /dev/null > Packages
gzip -9 -n -k Packages
bzip2 -9 -k Packages

{
    echo "Origin: Walleter"
    echo "Label: Walleter"
    echo "Suite: stable"
    echo "Version: 1.0"
    echo "Codename: ios"
    echo "Architectures: iphoneos-arm"
    echo "Components: main"
    echo "Description: Walleter — скидочные карты в Passbook для iOS 6 (+ SigPass)"
    echo "MD5Sum:"
    for f in Packages Packages.gz Packages.bz2; do
        echo " $(md5sum "$f" | cut -d' ' -f1) $(stat -c%s "$f") $f"
    done
    echo "SHA256:"
    for f in Packages Packages.gz Packages.bz2; do
        echo " $(sha256sum "$f" | cut -d' ' -f1) $(stat -c%s "$f") $f"
    done
} > Release

touch .nojekyll
echo "Repo built in $OUT:"
cat Packages
