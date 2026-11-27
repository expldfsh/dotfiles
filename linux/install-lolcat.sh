#!/usr/bin/env bash
set -euo pipefail

recipe=$(dirname -- "$0")/packages/expldfsh-lolcat/PKGBUILD
# Read the package name and version from the same recipe makepkg will build.
source "$recipe"
installed=$(pacman -Q -- "$pkgname" 2>/dev/null || true)
if [[ $installed == "$pkgname $pkgver-$pkgrel" && -x /usr/bin/lolcat ]] &&
    [[ $(/usr/bin/lolcat --version) == *'patched by expldfsh'* ]]; then
    echo "$installed is already installed."
    exit 0
fi

work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
install -m644 -- "$recipe" "$work/PKGBUILD"
cd -- "$work"
export SRCDEST="$work" PKGDEST="$work" SRCPKGDEST="$work" BUILDDIR="$work" LOGDEST="$work"
makepkg --syncdeps --install --clean
