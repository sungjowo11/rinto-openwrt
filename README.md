# HG680P ImmortalWrt (Minimal + OpenClash + Tailscale)

[English](#english) | [Bahasa Indonesia](#bahasa-indonesia)

---

## Bahasa Indonesia

Custom firmware **ImmortalWrt** berbasis **Amlogic S905X** khusus untuk **FiberHome HG680P** (dan kompatibel dengan ZTE B860H v1/v2). Didesain seringan mungkin (*no bloatware*) dengan fokus utama pada routing proxy (**OpenClash**) dan akses jaringan lokal jarak jauh (**Tailscale Subnet Router**).

### ✨ Fitur Utama
- **Tanpa Bloatware (Minimalist)**: Bersih dari paket berat seperti Docker, Samba, Transmission, Torrent, Aria2, dan DLNA.
- **OpenClash Pre-installed**: Termasuk core binary `mihomo` (`clash_meta`) versi ARM64 langsung di `/etc/openclash/core/clash_meta`.
- **Tailscale Subnet Router Ready**: IP Forwarding (`net.ipv4.ip_forward = 1`) sudah aktif secara default, siap dijadikan jembatan untuk mengakses IP kamera CCTV lokal (seperti Vi365) & Smart Pet Feeder dari luar rumah tanpa perlu install Tailscale di masing-masing perangkat.
- **Optimasi RAM**: Dilengkapi modul `zram-swap` agar penggunaan memori tetap stabil dan aman dari OOM crash pada STB RAM 1GB / 2GB.
- **Ophub Amlogic Service**: Dilengkapi `luci-app-amlogic` untuk mempermudah backup, restore, dan instalasi firmware dari SD card/Flashdisk langsung ke eMMC internal STB.
- **Tema Bersih**: Menggunakan antarmuka modern `luci-theme-argon`.

### 📋 Informasi Default Firmware
- **Alamat IP Default**: `192.168.1.1`
- **Username LuCI**: `root`
- **Password LuCI**: `password` (atau kosongkan saat first boot)
- **Nama WiFi Default**: `HG680P-OpenWrt` (Tanpa Password)

### 🚀 Cara Menghubungkan Tailscale untuk Akses CCTV Lokal
1. Masuk ke SSH HG680P melalui terminal:
   ```bash
   ssh root@192.168.1.1
   ```
2. Jalankan perintah aktivasi Tailscale sebagai **Subnet Router** & **Exit Node**:
   ```bash
   tailscale up --advertise-routes=192.168.1.0/24 --advertise-exit-node --accept-dns=false
   ```
   *(Sesuaikan `192.168.1.0/24` dengan segmen IP subnet LAN modem/kamera kamu).*
3. Buka link login yang muncul di terminal untuk mengautentikasi ke akun Tailscale kamu.
4. Di dashboard admin Tailscale (web):
   - Klik menu **Machines** → pilih mesin HG680P.
   - Klik **Edit route settings** → Centang / Approve subnet `192.168.1.0/24` dan exit node.
5. Pada HP kamu di luar rumah:
   - Hubungkan aplikasi Tailscale di HP.
   - Aktifkan fitur **Use Exit Node** (pilih HG680P) atau cukup biarkan route subnet aktif. Sekarang aplikasi kamera CCTV kamu (seperti Vi365) dapat dibuka serasa berada di jaringan Wi-Fi rumah!

### 🛠️ Cara Build Sendiri via GitHub Actions
1. Fork atau push repositori ini ke akun GitHub kamu.
2. Buka menu **Settings** > **Actions** > **General** > scroll ke bagian **Workflow permissions** > pilih **Read and write permissions** lalu klik **Save**.
3. Buka tab **Actions** di repo GitHub kamu.
4. Pilih workflow **Build HG680P ImmortalWrt (Minimal + OpenClash + Tailscale)** di panel kiri.
5. Klik **Run workflow**, pilih branch target kernel (disarankan `5.15.y` untuk kestabilan S905X), lalu klik tombol hijau **Run workflow**.
6. Tunggu proses selesai (~10-15 menit). Firmware flashable (`.img.gz`) akan otomatis tersedia di menu **Releases**.
7. Flash file `.img.gz` ke MicroSD / Flashdisk menggunakan [Rufus](https://rufus.ie/) atau [BalenaEtcher](https://etcher.balena.io/).

---

## English

Custom **ImmortalWrt** firmware for **Amlogic S905X** TV Boxes, tailored specifically for **FiberHome HG680P** (also compatible with ZTE B860H v1/v2). Designed with a **minimalist / no-bloatware** philosophy, focusing on high-speed proxy routing (**OpenClash**) and remote local network bridging (**Tailscale Subnet Router**).

### ✨ Highlights
- **Zero Bloatware**: Excludes heavy packages such as Docker, Samba, Transmission, Torrent clients, Aria2, and DLNA.
- **OpenClash Ready**: Includes pre-injected ARM64 `mihomo` (`clash_meta`) core binary directly in `/etc/openclash/core/clash_meta`.
- **Tailscale Subnet Router**: Pre-configured IP forwarding (`net.ipv4.ip_forward = 1`), enabling seamless remote access to local IP cameras (e.g. Vi365) and Smart Pet Feeders without installing Tailscale on each client device.
- **RAM Optimization**: `zram-swap` included out of the box to prevent Out of Memory (OOM) issues on 1GB / 2GB RAM TV boxes.
- **Ophub Amlogic Service**: Built-in `luci-app-amlogic` for flashing and booting directly from internal eMMC.
- **Modern UI**: Clean and responsive `luci-theme-argon` interface.

### 📋 Default Firmware Credentials
- **Default IP**: `192.168.1.1`
- **Username**: `root`
- **Password**: `password` (or blank on initial boot)
- **Default WiFi SSID**: `HG680P-OpenWrt` (Open / No password)

### 🚀 Setting Up Tailscale Subnet Router
1. Connect to HG680P via SSH:
   ```bash
   ssh root@192.168.1.1
   ```
2. Authenticate and advertise your home LAN subnet:
   ```bash
   tailscale up --advertise-routes=192.168.1.0/24 --advertise-exit-node --accept-dns=false
   ```
   *(Replace `192.168.1.0/24` with your actual home network IP range).*
3. Open the authentication URL printed in the terminal to bind the device to your Tailscale account.
4. On the Tailscale Web Admin Console:
   - Go to **Machines** → Select your HG680P node.
   - Select **Edit route settings** → Approve the subnet route and exit node.
5. On your smartphone when outside:
   - Connect Tailscale and select your HG680P as the **Exit Node**. You can now launch your Vi365 CCTV or smart pet feeder app seamlessly as if you were connected to your home Wi-Fi!

### 🛠️ Building with GitHub Actions
1. Push or fork this repository to your GitHub account.
2. In your repo, go to **Settings** > **Actions** > **General** > **Workflow permissions** > select **Read and write permissions** and save.
3. Navigate to the **Actions** tab.
4. Select **Build HG680P ImmortalWrt (Minimal + OpenClash + Tailscale)** from the left sidebar.
5. Click **Run workflow**, choose your preferred kernel (kernel `5.15.y` is recommended for S905X stability), and trigger the build.
6. The flashable image archive (`.img.gz`) will be published under the **Releases** tab once completed.
7. Burn the image to an SD Card or USB drive using [BalenaEtcher](https://etcher.balena.io/) or [Rufus](https://rufus.ie/).

---

### ⚖️ License & Acknowledgements
- Based on [ophub/amlogic-s9xxx-openwrt](https://github.com/ophub/amlogic-s9xxx-openwrt)
- Inspired by [dianariyanto/dianwrt](https://github.com/dianariyanto/dianwrt)
- Core routing: [vernesong/OpenClash](https://github.com/vernesong/OpenClash) & [MetaCubeX/mihomo](https://github.com/MetaCubeX/mihomo)
- Virtual mesh networking: [Tailscale](https://tailscale.com/)
