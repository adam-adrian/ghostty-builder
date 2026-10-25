# Maintainer: Adam Adrian <4.adam.adrian@gmail.com>

_pkgbase=ghostty
pkgname=(
    $_pkgbase-git
    $_pkgbase-shell-integration-git
    $_pkgbase-terminfo-git
    $_pkgbase-nautilus-git
)
pkgrel=1
pkgver=1.3.1.r3193.gcec8b92
pkgdesc="Fast, native, feature-rich terminal emulator (built from git main with x86-64-v3)"
arch=(x86_64)
url="https://github.com/ghostty-org/$_pkgbase"
license=(MIT)
depends=(
    bzip2
    fontconfig libfontconfig.so
    freetype2 libfreetype.so
    glibc
    glib2 libglib-2.0.so libgio-2.0.so libgobject-2.0.so
    gtk4 libgtk-4.so
    gtk4-layer-shell
    libx11
    harfbuzz libharfbuzz.so
    libadwaita libadwaita-1.so
    libpng
    oniguruma
    pixman
    wayland libwayland-client.so
    zlib
)
makedepends=(
    blueprint-compiler
    git
    pandoc-cli
    zig
)
source=(
    "git+$url.git"
    "ghostty-llvm.patch"
)
sha256sums=(
    'SKIP'
    '1df55089c6539501eab6c59b24625c016cd11c12f12d2181d72a5fb5b080502b'
)

pkgver() {
    cd "$_pkgbase"
    git describe --long --tags --abbrev=7 --match="v*" HEAD |
        sed 's/^v//;s/\([^-]*-g\)/r\1/;s/-/./g'
}

prepare() {
    cd "$_pkgbase"
    patch -p1 -i "$srcdir/ghostty-llvm.patch"
}

build() {
    cd "$_pkgbase"
    DESTDIR=build zig build \
        --summary all \
        --prefix "/usr" \
        -Doptimize=ReleaseFast \
        -Dcpu=x86_64_v3 \
        -Dgtk-x11=true \
        -Dpie=true \
        -Demit-docs \
        -Dversion-string="${pkgver%.r*}-r${pkgver#*.r}-$pkgrel-arch" \
        --build-id=sha1
}

package_ghostty-git() {
    depends+=("${_pkgbase}-shell-integration-git" "${_pkgbase}-terminfo-git")
    provides=("${pkgname%-git}=$pkgver")
    conflicts=(${pkgname%-git})
    optdepends+=("ghostty-nautilus: Open in Ghostty context menu in GNOME Files")
    cd "$_pkgbase"
    cp -a build/* "$pkgdir/"
    install -Dm0644 -t "${pkgdir}/usr/share/licenses/$pkgname/" LICENSE
    rm -r "$pkgdir"/usr/share/terminfo
    rm -r "$pkgdir"/usr/share/ghostty/shell-integration
    rm -r "$pkgdir"/usr/share/nautilus-python
}

package_ghostty-shell-integration-git() {
    pkgdesc='Shell integration scripts for ghostty'
    depends=()
    provides=("${pkgname%-git}=$pkgver")
    conflicts=(${pkgname%-git})
    cd "$_pkgbase"
    mkdir -p "$pkgdir/usr/share/ghostty/shell-integration"
    cp -r build/usr/share/ghostty/shell-integration/* "$pkgdir/usr/share/ghostty/shell-integration/"
}

package_ghostty-terminfo-git() {
    pkgdesc='Terminfo for ghostty'
    depends=()
    provides=("${pkgname%-git}=$pkgver")
    conflicts=(${pkgname%-git})
    cd "$_pkgbase"
    mkdir -p "$pkgdir/usr/share/terminfo"
    cp -r build/usr/share/terminfo/* "$pkgdir/usr/share/terminfo/"
    rm -f "$pkgdir/usr/share/terminfo/g/ghostty"
    rmdir "$pkgdir/usr/share/terminfo/g" 2>/dev/null || true
}

package_ghostty-nautilus-git() {
    pkgdesc='Open in Ghostty for GNOME Files'
    depends=(ghostty nautilus-python)
    provides=("${pkgname%-git}=$pkgver")
    conflicts=(${pkgname%-git})
    license=(GPL-2.0-or-later)
    cd "$_pkgbase"
    mkdir -p "$pkgdir"/usr/share/nautilus-python/
    cp -r build/usr/share/nautilus-python/* "$pkgdir"/usr/share/nautilus-python/
}
