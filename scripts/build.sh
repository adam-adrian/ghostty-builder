#!/usr/bin/env bash
set -euo pipefail

# 1. Update keyring and install base packages
pacman -Sy --noconfirm archlinux-keyring
pacman -Su --noconfirm --needed git sudo pacman

# 2. Setup unprivileged builder user for makepkg
if ! id -u builder >/dev/null 2>&1; then
  useradd -m -s /bin/bash builder
  echo "builder ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/builder
  chmod 0440 /etc/sudoers.d/builder
fi

mkdir -p /home/builder/.cache/zig
chown -R builder:builder /home/builder/.cache

# 3. Build Ghostty as builder user
su builder -c '
  set -euo pipefail
  export ZIG_GLOBAL_CACHE_DIR=/home/builder/.cache/zig

  rm -rf /tmp/ghostty-git
  git clone https://aur.archlinux.org/ghostty-git.git /tmp/ghostty-git
  cd /tmp/ghostty-git

  # Optimize for modern x86-64-v3 microarchitecture (AVX2, BMI2, FMA)
  sed -i "s/-Dcpu=baseline/-Dcpu=x86-64-v3/" PKGBUILD

  # Allow zig to fetch missing transitive dependencies online
  sed -i "/--system/d" PKGBUILD

  # Persist downloaded package tarballs into the global cache
  sed -i "s|ZIG_GLOBAL_CACHE_DIR=.*fetch-zig-cache.sh|./nix/build-support/fetch-zig-cache.sh|" PKGBUILD

  makepkg -s --noconfirm
  cp *.pkg.tar.zst /dist/

  # Generate pacman repository database
  cd /dist
  repo-add ghostty.db.tar.gz *.pkg.tar.zst

  # Ensure database files are regular files, not symlinks
  rm -f ghostty.db ghostty.files
  cp -a ghostty.db.tar.gz ghostty.db
  cp -a ghostty.files.tar.gz ghostty.files

  # Extract upstream build metadata
  cd /tmp/ghostty-git
  UPSTREAM_COMMIT=$(git -C src/ghostty rev-parse HEAD 2>/dev/null || echo "unknown")
  UPSTREAM_SHORT=$(git -C src/ghostty rev-parse --short HEAD 2>/dev/null || echo "unknown")
  UPSTREAM_MSG=$(git -C src/ghostty log -1 --pretty=%s 2>/dev/null || echo "")
  UPSTREAM_DATE=$(git -C src/ghostty log -1 --pretty=%ci 2>/dev/null || echo "")
  PKG_VER=$(ls ghostty-git-*.pkg.tar.zst | head -n1 | sed -E "s/ghostty-git-(.*)-x86_64\.pkg\.tar\.zst/\1/")
  BUILD_DATE=$(date -u "+%Y-%m-%d %H:%M UTC")

  echo "Ghostty Git ${PKG_VER} (x86-64-v3)" > /dist/release_title.txt

  if [ -n "${PREV_SHA:-}" ] && [ "${PREV_SHA}" != "${UPSTREAM_COMMIT}" ]; then
    COMPARE_LINE="* **Changes:** [View commits since previous build](https://github.com/ghostty-org/ghostty/compare/${PREV_SHA}...${UPSTREAM_COMMIT})"
  else
    COMPARE_LINE="* **Changes:** Initial build or commit unchanged"
  fi

  cat << EOF > /dist/release_notes.md
## Ghostty Git (${PKG_VER})

Automated pacman repository tracking ghostty-org/ghostty:main.

### Upstream Source
* **Commit:** [${UPSTREAM_SHORT}](https://github.com/ghostty-org/ghostty/commit/${UPSTREAM_COMMIT})
* **Message:** *${UPSTREAM_MSG}*
${COMPARE_LINE}
* **Arch Target:** x86-64-v3 (AVX2, BMI2, FMA)
* **Build Time:** ${BUILD_DATE}

### Pacman Configuration

Tambahkan ke /etc/pacman.conf:

\`\`\`ini
[ghostty]
SigLevel = Optional TrustAll
Server = https://github.com/${GITHUB_REPOSITORY}/releases/download/repo
\`\`\`

Sinkronkan dan pasang:
\`\`\`bash
sudo pacman -Sy ghostty-git
\`\`\`

### Artifacts & Packages
* ghostty-git: Binary terminal emulator Ghostty
* ghostty-terminfo-git: Terminfo Ghostty untuk shell lokal
* ghostty-shell-integration-git: Skrip integrasi shell (bash, zsh, fish)
* ghostty-nautilus-git: Integrasi context menu Open in Ghostty untuk GNOME Files (Nautilus)
* ghostty-git-debug: Simbol debug untuk troubleshooting

### SHA256 Checksums
\`\`\`text
$(cd /dist && sha256sum *.pkg.tar.zst)
\`\`\`
EOF
'
