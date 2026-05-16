# Maintainer: Erik Dubois <erik.dubois@gmail.com>
# Based on: Steven Barrett <steven@liquorix.net> (Liquorix/Zen kernel)
#
# linux-kiro-lqx — Liquorix PDS kernel, built for this machine only.
# Scheduler : PDS (Project-C alt scheduler, from the lqx patch)
# HZ        : 1000
# Preempt   : full
# CPU       : native (-march=native, always)
# Localmod  : yes (always — requires modprobed-db)

### Tweak kernel options via nconfig before build
: "${_makenconfig:=no}"

### Tweak kernel options via xconfig before build
: "${_makexconfig:=no}"

### Use the running kernel's .config as base instead of the stored config
: "${_use_current:=no}"

### Clang LTO mode — "none", "full", or "thin"
: "${_use_llvm_lto:=none}"

### Optional extra packages
: "${_build_nvidia_open:=no}"
: "${_build_zfs:=no}"
: "${_build_r8125:=no}"
: "${_build_debug:=no}"

# ── Internal helpers ──────────────────────────────────────────────────────────

_is_lto_kernel() {
    [[ "$_use_llvm_lto" = "thin" || "$_use_llvm_lto" = "full" ]]
    return $?
}

# ── Package metadata ──────────────────────────────────────────────────────────

pkgbase="linux-kiro-lqx"
_major=7.0
_minor=7
_lqxrel=lqx1
pkgver=${_major}.${_minor}
pkgrel=1
_srcname="linux-${_major}"
pkgdesc='Linux Liquorix PDS kernel for gaming and desktop by Kiro'
_kernver="$pkgver-$pkgrel"
_kernuname="${pkgver}-kiro-lqx"
arch=('x86_64')
url="https://github.com/erikdubois/linux-kiro-lqx"
license=('GPL-2.0-only')
options=('!strip' '!debug' '!lto')
makedepends=(
  bc
  binutils
  cpio
  gettext
  glibc
  libelf
  libgcc
  openssl
  pahole
  perl
  python
  rust
  rust-bindgen
  rust-src
  tar
  xxhash
  xz
  zlib
  zstd
)

_nv_ver=595.58.03
_nv_open_pkg="NVIDIA-kernel-module-source-${_nv_ver}"

source=(
    "https://cdn.kernel.org/pub/linux/kernel/v7.x/linux-${_major}.tar.xz"
    "v${_major}.${_minor}-${_lqxrel}.patch"
    "config"
)

if _is_lto_kernel; then
    makedepends+=(clang llvm lld)
    BUILD_FLAGS=(
        CC=clang
        LD=ld.lld
        LLVM=1
        LLVM_IAS=1
    )
fi

if [ "$_build_zfs" = "yes" ]; then
    makedepends+=(git)
    source+=("git+https://github.com/cachyos/zfs.git#commit=0829cf892b5d7b3a0e8aa76cc7aca02b84f62557")
fi

if [ "$_build_nvidia_open" = "yes" ]; then
    source+=("https://download.nvidia.com/XFree86/${_nv_open_pkg%"-$_nv_ver"}/${_nv_open_pkg}.tar.xz")
fi

if [ "$_build_r8125" = "yes" ]; then
    source+=("git+https://github.com/aravance/r8125.git")
fi

export KBUILD_BUILD_HOST=kiro
export KBUILD_BUILD_USER="$pkgbase"
export KBUILD_BUILD_TIMESTAMP="$(date -Ru${SOURCE_DATE_EPOCH:+d @$SOURCE_DATE_EPOCH})"

_die() { error "$@" ; exit 1; }

# ── prepare ───────────────────────────────────────────────────────────────────

prepare() {
    cd "$_srcname"

    echo "Applying lqx patch v${_major}.${_minor}-${_lqxrel}..."
    patch -Np1 < "../v${_major}.${_minor}-${_lqxrel}.patch"

    echo "Setting version..."
    echo "-$pkgrel" > localversion.10-pkgrel
    echo "${pkgbase#linux}" > localversion.20-pkgname

    echo "Setting config..."
    cp ../config .config

    # Native CPU — always on for this machine
    scripts/config -e X86_NATIVE_CPU

    # LTO
    case "$_use_llvm_lto" in
        thin) scripts/config -e LTO_CLANG_THIN;;
        full) scripts/config -e LTO_CLANG_FULL;;
        none) scripts/config -e LTO_NONE;;
        *) _die "Invalid _use_llvm_lto value: $_use_llvm_lto";;
    esac

    # Use running kernel's config if requested
    if [ "$_use_current" = "yes" ]; then
        if [[ -s /proc/config.gz ]]; then
            echo "Extracting config from /proc/config.gz..."
            zcat /proc/config.gz > ./.config
        else
            warning "No /proc/config.gz — skipping _use_current"
        fi
    fi

    # localmodconfig — always enabled; this kernel is built for this machine only
    local modprobed_db="$HOME/.config/modprobed.db"
    if [ -e "$modprobed_db" ]; then
        echo "Running make localmodconfig..."
        make "${BUILD_FLAGS[@]}" LSMOD="$modprobed_db" localmodconfig
    else
        _die "modprobed.db not found at $modprobed_db — install modprobed-db and run 'modprobed-db store'"
    fi

    # Arch-specific tweaks (from linux-lqx reference PKGBUILD)
    scripts/config -e CONFIG_DEBUG_INFO_DWARF5
    scripts/config --set-str CONFIG_SECURITY_TOMOYO_POLICY_LOADER      "/usr/bin/tomoyo-init"
    scripts/config --set-str CONFIG_SECURITY_TOMOYO_ACTIVATION_TRIGGER "/usr/lib/systemd/systemd"
    scripts/config --set-str CONFIG_LSM                                 "landlock,lockdown,yama,bpf"

    echo "Updating config for new options..."
    make "${BUILD_FLAGS[@]}" olddefconfig
    diff -u ../config .config || :

    make -s kernelrelease > version
    echo "Prepared $pkgbase version $(<version)"

    [ "$_makenconfig" = "yes" ] && make "${BUILD_FLAGS[@]}" nconfig
    [ "$_makexconfig" = "yes" ] && make "${BUILD_FLAGS[@]}" xconfig

    echo "Saving config snapshot..."
    local basedir
    basedir="$(dirname "$(readlink "${srcdir}/config")")"
    cat .config > "${basedir}/config-${pkgver}-${pkgrel}${pkgbase#linux}"
}

# ── build ─────────────────────────────────────────────────────────────────────

_sign_modules() {
    local modulesdir="$1"
    local sign_script="${srcdir}/${_srcname}/scripts/sign-file"
    local sign_key
    sign_key="$(grep -Po 'CONFIG_MODULE_SIG_KEY="\K[^"]*' "${srcdir}/${_srcname}/.config")"
    [[ "$sign_key" =~ ^/ ]] || sign_key="${srcdir}/${_srcname}/${sign_key}"
    local sign_cert="${srcdir}/${_srcname}/certs/signing_key.x509"
    local hash_algo
    hash_algo="$(grep -Po 'CONFIG_MODULE_SIG_HASH="\K[^"]*' "${srcdir}/${_srcname}/.config")"
    local strip_bin
    _is_lto_kernel && strip_bin="llvm-strip" || strip_bin="strip"

    find "$modulesdir" -type f -name '*.ko' -print \
        -exec "${strip_bin}" --strip-debug '{}' \; \
        -exec "${sign_script}" "${hash_algo}" "${sign_key}" "${sign_cert}" '{}' \;
}

build() {
    cd "$_srcname"
    make "${BUILD_FLAGS[@]}" -j"$(nproc)" all
    make -C tools/bpf/bpftool vmlinux.h feature-clang-bpf-co-re=1

    local MODULE_FLAGS=(
        KERNEL_UNAME="${_kernuname}"
        IGNORE_PREEMPT_RT_PRESENCE=1
        SYSSRC="${srcdir}/${_srcname}"
        SYSOUT="${srcdir}/${_srcname}"
    )

    if [ "$_build_nvidia_open" = "yes" ]; then
        cd "${srcdir}/${_nv_open_pkg}"
        MODULE_FLAGS+=(IGNORE_CC_MISMATCH=yes)
        CFLAGS= CXXFLAGS= LDFLAGS= make "${BUILD_FLAGS[@]}" "${MODULE_FLAGS[@]}" -j"$(nproc)" modules
    fi

    if [ "$_build_zfs" = "yes" ]; then
        cd "${srcdir}/zfs"
        local CONFIGURE_FLAGS=()
        _is_lto_kernel && CONFIGURE_FLAGS+=("KERNEL_LLVM=1")
        ./autogen.sh
        sed -i "s|\$(uname -r)|${_kernuname}|g" configure
        ./configure "${CONFIGURE_FLAGS[@]}" --prefix=/usr --sysconfdir=/etc --sbindir=/usr/bin \
            --libdir=/usr/lib --datadir=/usr/share --includedir=/usr/include \
            --with-udevdir=/lib/udev --libexecdir=/usr/lib/zfs --with-config=kernel \
            --with-linux="${srcdir}/$_srcname"
        make "${BUILD_FLAGS[@]}"
    fi

    if [ "$_build_r8125" = "yes" ]; then
        cd "${srcdir}/r8125"
        make "${BUILD_FLAGS[@]}" KERNELDIR="$srcdir/$_srcname" modules
    fi
}

# ── package functions ─────────────────────────────────────────────────────────

_package() {
    pkgdesc="The $pkgdesc kernel and modules"
    depends=('coreutils' 'kmod' 'initramfs')
    optdepends=(
        'wireless-regdb: to set the correct wireless channels of your country'
        'linux-firmware: firmware images needed for some devices'
        'modprobed-db: Keeps track of EVERY kernel module that has ever been probed'
    )
    provides=(VIRTUALBOX-GUEST-MODULES WIREGUARD-MODULE KSMBD-MODULE V4L2LOOPBACK-MODULE NTSYNC-MODULE VHBA-MODULE)

    cd "$_srcname"
    local modulesdir="$pkgdir/usr/lib/modules/$(<version)"

    echo "Installing boot image..."
    install -Dm644 "$(make -s image_name)" "$modulesdir/vmlinuz"
    echo "$pkgbase" | install -Dm644 /dev/stdin "$modulesdir/pkgbase"

    echo "Installing modules..."
    ZSTD_CLEVEL=19 make "${BUILD_FLAGS[@]}" INSTALL_MOD_PATH="$pkgdir/usr" INSTALL_MOD_STRIP=1 \
        DEPMOD=/doesnt/exist modules_install

    rm "$modulesdir/build"
}

_package-headers() {
    pkgdesc="Headers and scripts for building modules for the $pkgdesc kernel"
    depends=(binutils glibc libelf libgcc openssl pahole xxhash zlib zstd "${pkgbase}")
    provides=(LINUX-HEADERS)
    _is_lto_kernel && depends+=(clang llvm lld)

    cd "${_srcname}"
    local builddir="$pkgdir/usr/lib/modules/$(<version)/build"

    echo "Installing build files..."
    install -Dt "$builddir" -m644 .config Makefile Module.symvers System.map \
        localversion.* version vmlinux
    install -Dt "$builddir" -m644 tools/bpf/bpftool/vmlinux.h
    install -Dt "$builddir/kernel" -m644 kernel/Makefile
    install -Dt "$builddir/arch/x86" -m644 arch/x86/Makefile
    cp -t "$builddir" -a scripts
    ln -srt "$builddir" "$builddir/scripts/gdb/vmlinux-gdb.py"
    install -Dt "$builddir/tools/objtool" tools/objtool/objtool

    if [ -f tools/bpf/resolve_btfids/resolve_btfids ]; then
        install -Dt "$builddir/tools/bpf/resolve_btfids" tools/bpf/resolve_btfids/resolve_btfids
    fi

    echo "Installing headers..."
    cp -t "$builddir" -a include
    cp -t "$builddir/arch/x86" -a arch/x86/include
    install -Dt "$builddir/arch/x86/kernel" -m644 arch/x86/kernel/asm-offsets.s
    install -Dt "$builddir/drivers/md" -m644 drivers/md/*.h
    install -Dt "$builddir/net/mac80211" -m644 net/mac80211/*.h
    install -Dt "$builddir/drivers/media/i2c" -m644 drivers/media/i2c/msp3400-driver.h
    install -Dt "$builddir/drivers/media/usb/dvb-usb" -m644 drivers/media/usb/dvb-usb/*.h
    install -Dt "$builddir/drivers/media/dvb-frontends" -m644 drivers/media/dvb-frontends/*.h
    install -Dt "$builddir/drivers/media/tuners" -m644 drivers/media/tuners/*.h
    install -Dt "$builddir/drivers/iio/common/hid-sensors" -m644 drivers/iio/common/hid-sensors/*.h

    echo "Installing KConfig files..."
    find . -name 'Kconfig*' -exec install -Dm644 {} "$builddir/{}" \;

    compgen -G "rust/*.rmeta" &>/dev/null && install -Dt "$builddir/rust" -m644 rust/*.rmeta
    compgen -G "rust/*.so"    &>/dev/null && install -Dt "$builddir/rust" rust/*.so

    echo "Installing unstripped VDSO..."
    make INSTALL_MOD_PATH="$pkgdir/usr" vdso_install link=

    echo "Removing unneeded architectures..."
    local arch
    for arch in "$builddir/arch/"/*/; do
        [[ $arch = */x86/ ]] && continue
        rm -r "$arch"
    done

    rm -r "$builddir/Documentation"
    find -L "$builddir" -type l -printf 'Removing %P\n' -delete
    find "$builddir" -type f -name '*.o' -printf 'Removing %P\n' -delete

    echo "Stripping build tools..."
    local file
    while read -rd '' file; do
        case "$(file -Sib "$file")" in
            application/x-sharedlib\;*)      strip -v $STRIP_SHARED "$file";;
            application/x-archive\;*)        strip -v $STRIP_STATIC "$file";;
            application/x-executable\;*)     strip -v $STRIP_BINARIES "$file";;
            application/x-pie-executable\;*) strip -v $STRIP_SHARED "$file";;
        esac
    done < <(find "$builddir" -type f -perm -u+x ! -name vmlinux -print0)

    strip -v $STRIP_STATIC "$builddir/vmlinux"
    mkdir -p "$pkgdir/usr/src"
    ln -sr "$builddir" "$pkgdir/usr/src/$pkgbase"
}

_package-dbg() {
    pkgdesc="Non-stripped vmlinux for the $pkgdesc kernel"
    depends=("${pkgbase}-headers")

    cd "${_srcname}"
    mkdir -p "$pkgdir/usr/src/debug/${pkgbase}"
    install -Dt "$pkgdir/usr/src/debug/${pkgbase}" -m644 vmlinux
}

_package-zfs() {
    pkgdesc="zfs module for the $pkgdesc kernel"
    depends=('pahole' "${pkgbase}=${_kernver}")
    provides=('ZFS-MODULE')
    license=('CDDL')

    cd "$_srcname"
    local modulesdir="$pkgdir/usr/lib/modules/$(<version)/extramodules"
    cd "${srcdir}/zfs"
    install -dm755 "${modulesdir}"
    install -m644 module/*.ko "${modulesdir}"
    _sign_modules "${modulesdir}"
    find "$pkgdir" -name '*.ko' -exec zstd --rm -19 -T0 {} +
}

_package-nvidia-open() {
    pkgdesc="nvidia open modules of ${_nv_ver} driver for the ${pkgbase} kernel"
    depends=("$pkgbase=$_kernver" "nvidia-utils=${_nv_ver}" "libglvnd")
    provides=('NVIDIA-MODULE')
    conflicts=("$pkgbase-nvidia")
    license=('MIT AND GPL-2.0-only')

    cd "$_srcname"
    local modulesdir="$pkgdir/usr/lib/modules/$(<version)/extramodules"
    cd "${srcdir}/${_nv_open_pkg}"
    install -dm755 "${modulesdir}"
    install -m644 kernel-open/*.ko "${modulesdir}"
    install -Dt "$pkgdir/usr/share/licenses/${pkgname}" -m644 COPYING
    _sign_modules "${modulesdir}"
    find "$pkgdir" -name '*.ko' -exec zstd --rm -19 -T0 {} +
}

_package-r8125() {
    pkgdesc="r8125 module for the $pkgbase kernel"
    depends=("$pkgbase=$_kernver")
    license=('GPL-2.0-only')

    cd "$_srcname"
    local modulesdir="$pkgdir/usr/lib/modules/$(<version)/extramodules"
    cd "${srcdir}/r8125"
    install -dm755 "${modulesdir}"
    install -m644 src/*.ko "${modulesdir}"
    _sign_modules "${modulesdir}"
    find "$pkgdir" -name '*.ko' -exec zstd --rm -19 -T0 {} +

    install -dm755 "${pkgdir}/usr/lib/modprobe.d"
    echo "install r8169 /usr/bin/modprobe r8125 || /usr/bin/modprobe --ignore-install r8169" \
        > "${pkgdir}/usr/lib/modprobe.d/${pkgname}.conf"
}

# ── pkgname array ─────────────────────────────────────────────────────────────

pkgname=("$pkgbase")
[ "$_build_debug"        = "yes" ] && pkgname+=("$pkgbase-dbg")
pkgname+=("$pkgbase-headers")
[ "$_build_zfs"          = "yes" ] && pkgname+=("$pkgbase-zfs")
[ "$_build_nvidia_open"  = "yes" ] && pkgname+=("$pkgbase-nvidia-open")
[ "$_build_r8125"        = "yes" ] && pkgname+=("$pkgbase-r8125")

for _p in "${pkgname[@]}"; do
    eval "package_${_p}() {
    $(declare -f "_package${_p#$pkgbase}")
    _package${_p#$pkgbase}
    }"
done

b2sums=('3d9795083c8938f80f480de0d10bfd9c525640e59d5c7f22983de3f12ee42c84c31be902cafb05579ddb1c32bac5ed06b0d4953f9705450be185bd2d9ab08f89'
        '6624d943b91aa7ded27ad6affa176984ebbdb61083ac741cde04831074799eb42f59a0ab1377a50211ebee2335212b11115a53219132d6f8aa1c9b315c4c806d'
        '04ec43d342e0efcd85836567285725e0dea20c94b679c3aaafe223635e32b2cb3314b48af0c1cb27dbbdaf2603b7f524ff9798aae097b1bdec62d5648673fbe3')
