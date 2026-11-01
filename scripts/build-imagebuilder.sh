#!/bin/bash
#================================================================================================
# Custom ImageBuilder Script for HG680P (Amlogic S905X)
# Minimalist / No-Bloatware + OpenClash + Tailscale
#================================================================================================

set -e

make_path="${PWD}"
openwrt_dir="imagebuilder"
imagebuilder_path="${make_path}/${openwrt_dir}"
custom_files_path="${make_path}/files"
custom_config_file="${make_path}/config/custom_packages.config"
output_path="${make_path}/output"
tmp_path="${imagebuilder_path}/tmp"

STEPS="[\033[95m STEPS \033[0m]"
INFO="[\033[94m INFO \033[0m]"
SUCCESS="[\033[92m SUCCESS \033[0m]"
ERROR="[\033[91m ERROR \033[0m]"

error_msg() {
    echo -e "${ERROR} ${1}"
    exit 1
}

# 1. Parse branch and target
releases_branch="${1:-immortalwrt:24.10.6}"
op_source="${releases_branch%%:*}"
op_branch="${releases_branch##*:}"

echo -e "${INFO} Selected Source: ${op_source}, Branch: ${op_branch}"

# 2. Download ImageBuilder
cd "${make_path}"
echo -e "${STEPS} Downloading ImageBuilder for ${op_source} ${op_branch} (armsr/armv8)..."

if [[ "${op_source}" == "immortalwrt" ]]; then
    download_host="downloads.immortalwrt.org"
else
    download_host="downloads.openwrt.org"
fi

download_url="https://${download_host}/releases/${op_branch}/targets/armsr/armv8/${op_source}-imagebuilder-${op_branch}-armsr-armv8.Linux-x86_64.tar.zst"
echo -e "${INFO} Fetching from: ${download_url}"
curl -fsSOL "${download_url}" || error_msg "Failed to download ImageBuilder from ${download_url}"

echo -e "${STEPS} Extracting ImageBuilder archive..."
tar -I zstd -xf *-imagebuilder-*.tar.zst -C . && rm -f *-imagebuilder-*.tar.zst
mv -f *-imagebuilder-* "${openwrt_dir}"

cd "${imagebuilder_path}"

# 3. Adjust ImageBuilder .config
echo -e "${STEPS} Adjusting .config settings..."
if [[ -s ".config" ]]; then
    sed -i "s|CONFIG_TARGET_ROOTFS_CPIOGZ=.*|# CONFIG_TARGET_ROOTFS_CPIOGZ is not set|g" .config
    sed -i "s|CONFIG_TARGET_ROOTFS_EXT4FS=.*|# CONFIG_TARGET_ROOTFS_EXT4FS is not set|g" .config
    sed -i "s|CONFIG_TARGET_ROOTFS_SQUASHFS=.*|# CONFIG_TARGET_ROOTFS_SQUASHFS is not set|g" .config
    sed -i "s|CONFIG_TARGET_IMAGES_GZIP=.*|# CONFIG_TARGET_IMAGES_GZIP is not set|g" .config
    sed -i "s|CONFIG_TARGET_ROOTFS_TARGZ=.*|CONFIG_TARGET_ROOTFS_TARGZ=y|g" .config
else
    error_msg "No .config found in ImageBuilder."
fi

# 4. Prepare extra custom packages (luci-app-amlogic & luci-app-openclash)
echo -e "${STEPS} Downloading custom plugins (luci-app-amlogic & luci-app-openclash)..."
mkdir -p packages && cd packages

is_apk=false
if grep -q "CONFIG_USE_APK=y" ../.config 2>/dev/null; then
    is_apk=true
    echo -e "${INFO} Detected APK-based ImageBuilder (OpenWrt/ImmortalWrt 25.12+)."
else
    echo -e "${INFO} Detected OPKG-based ImageBuilder (OpenWrt/ImmortalWrt 24.10)."
fi

# Download luci-app-amlogic (Ophub STB tool)
amlogic_api="https://api.github.com/repos/ophub/luci-app-amlogic/releases"
amlogic_tag="$(curl -s ${amlogic_api} | grep -oP '(?<="tag_name": ")[^"]+' | grep "\-js$" | sort -Vur | head -n1 || true)"
if [[ -n "${amlogic_tag}" ]]; then
    echo -e "${INFO} Latest luci-app-amlogic tag: ${amlogic_tag}"
    if [ "$is_apk" = true ]; then
        amlogic_urls=$(curl -s ${amlogic_api} | grep "browser_download_url" | grep "${amlogic_tag}" | grep -oE "https://[^\"]+\.apk" || true)
    else
        amlogic_urls=$(curl -s ${amlogic_api} | grep "browser_download_url" | grep "${amlogic_tag}" | grep -oE "https://[^\"]+\.ipk" || true)
    fi
    for u in ${amlogic_urls}; do
        curl -fsSLO "${u}" || true
    done
fi

# Download luci-app-openclash
echo -e "${INFO} Fetching latest luci-app-openclash..."
openclash_api="https://api.github.com/repos/vernesong/OpenClash/releases"
openclash_tag="$(curl -s ${openclash_api} | grep -oP '(?<="tag_name": ")[^"]+' | head -n1 || true)"
if [[ -n "${openclash_tag}" ]]; then
    echo -e "${INFO} Latest OpenClash tag: ${openclash_tag}"
    if [ "$is_apk" = true ]; then
        openclash_pkg_url=$(curl -s ${openclash_api} | grep "browser_download_url" | grep -E "luci-app-openclash.*\.apk" | head -n1 | cut -d '"' -f 4 || true)
    else
        openclash_pkg_url=$(curl -s ${openclash_api} | grep "browser_download_url" | grep -E "luci-app-openclash.*\.ipk" | head -n1 | cut -d '"' -f 4 || true)
    fi
    if [[ -n "${openclash_pkg_url}" ]]; then
        echo -e "${INFO} Downloading OpenClash: ${openclash_pkg_url}"
        curl -fsSLO "${openclash_pkg_url}" || true
    fi
fi

# Clean up and fix APK filenames if on APK-based system
if [ "$is_apk" = true ]; then
    rm -f *.ipk 2>/dev/null || true
    for file in *.apk; do
        [ -e "$file" ] || continue
        new_file=$(echo "${file}" | sed -E 's/\.([a-f0-9]{7}\.apk)/~\1/')
        if [[ "${file}" != "${new_file}" ]]; then
            mv -f "${file}" "${new_file}" || true
            echo -e "${INFO} Renamed: ${file} -> ${new_file}"
        fi
    done
else
    rm -f *.apk 2>/dev/null || true
fi

cd "${imagebuilder_path}"

# 5. Inject Mihomo (Clash.Meta) Core & Custom Files into files overlay
echo -e "${STEPS} Preparing filesystem overlay..."
mkdir -p files/etc/openclash/core files/etc/sysctl.d files/etc

# Copy workspace custom files
if [[ -d "${custom_files_path}" ]]; then
    cp -rf "${custom_files_path}"/* files/
fi

# Download pre-built Mihomo (Clash.Meta) ARM64 binary so OpenClash works immediately
echo -e "${INFO} Downloading Mihomo (Clash.Meta) arm64-v8a binary..."
meta_api="https://api.github.com/repos/MetaCubeX/mihomo/releases"
meta_tag="$(curl -s ${meta_api} | grep -oP '(?<="tag_name": ")[^"]+' | head -n1 || true)"
if [[ -n "${meta_tag}" ]]; then
    meta_url=$(curl -s ${meta_api} | grep "browser_download_url" | grep "linux-arm64-v8a" | grep -E "\.gz$" | head -n1 | cut -d '"' -f 4 || true)
    if [[ -n "${meta_url}" ]]; then
        echo -e "${INFO} Fetching Mihomo from: ${meta_url}"
        curl -fsSL "${meta_url}" -o /tmp/mihomo.gz || true
        if [[ -f /tmp/mihomo.gz ]]; then
            gzip -dc /tmp/mihomo.gz > files/etc/openclash/core/clash_meta
            chmod 755 files/etc/openclash/core/clash_meta
            echo -e "${SUCCESS} Mihomo core placed at /etc/openclash/core/clash_meta"
        fi
    fi
fi

# 6. Parse custom package configuration
echo -e "${STEPS} Loading custom package configuration..."
config_packages=""
if [[ -s "${custom_config_file}" ]]; then
    config_packages="$(sed -n 's/^CONFIG_PACKAGE_\(.*\)=y$/\1/p' "${custom_config_file}" | tr '\n' ' ')"
fi

# Base Minimal Packages (STB system utilities + LuCI + Network essentials)
# Explicitly exclude bloatware (-docker -samba -transmission -aria2 -qbittorrent)
my_packages="\
    base-files bash busybox bzip2 ca-bundle ca-certificates coreutils coreutils-nohup curl \
    e2fsprogs f2fs-tools fdisk gzip kmod-brcmfmac kmod-brcmutil kmod-cfg80211 kmod-mac80211 \
    kmod-usb-net kmod-usb-net-rtl8152 kmod-usb-net-asix kmod-usb-net-asix-ax88179 \
    losetup mount-utils openssl-util parted pigz ppp ppp-mod-pppoe tar tune2fs \
    uclient-fetch uhttpd uhttpd-mod-ubus unzip usb-modeswitch wget-ssl which wpad-basic-mbedtls \
    zram-swap kmod-zram \
    luci luci-base luci-compat luci-mod-admin-full luci-mod-network luci-mod-status luci-mod-system \
    luci-theme-argon luci-app-amlogic \
    ${config_packages} \
    "

# 7. Build Rootfs with ImageBuilder
echo -e "${STEPS} Running ImageBuilder make image..."
make image PROFILE="" PACKAGES="${my_packages}" FILES="files"

# 8. Post-build: Extract & package rootfs for Ophub script
echo -e "${STEPS} Post-processing rootfs output..."
mkdir -p "${output_path}"
original_archive="$(ls -1 bin/targets/*/*/*rootfs.tar.gz 2>/dev/null | head -n 1)"

if [[ ! -f "${original_archive}" ]]; then
    error_msg "Build failed: rootfs.tar.gz not found!"
fi

echo -e "${INFO} Packaging final rootfs archive: ${original_archive}"
cp -f "${original_archive}" "${output_path}/openwrt-armsr-armv8-generic-rootfs.tar.gz"

echo -e "${SUCCESS} Rootfs build completed successfully! Output: ${output_path}/openwrt-armsr-armv8-generic-rootfs.tar.gz"
