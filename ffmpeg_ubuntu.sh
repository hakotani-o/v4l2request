#!/bin/bash
set -e # エラーが発生したらその時点で停止
set -x

export DEBEMAIL="user@localhost"
export DEBFULLNAME="Panthor Builder"
export DEB_CFLAGS_APPEND="-O2 -mcpu=cortex-a76.cortex-a55+crypto+dotprod+nosve -fno-plt"
export DEB_CXXFLAGS_APPEND="-O2 -mcpu=cortex-a76.cortex-a55+crypto+dotprod+nosve -fno-plt"

# 1. 作業用のディレクトリを作成して移動

# 最新 ffmpeg ソース（例: GitHubからcloneしたもの）
git clone \
  --branch rk3588-hevc-rps-controls \
  --single-branch \
  https://github.com/ryanfitz/FFmpeg.git \
  ffmpeg-v4l2request

# 2. 依存関係のインストールと、公式ソースコードのダウンロード
sudo apt update
sudo apt install -y \
  build-essential git pkg-config meson ninja-build python3 python3-jinja2 \
  linux-libc-dev v4l-utils media-types \
  libdrm-dev libudev-dev libdisplay-info-dev \
  libegl1-mesa-dev libgles2-mesa-dev libgbm-dev libvulkan-dev \
  libwayland-dev wayland-protocols libxkbcommon-dev \
  libass-dev libasound2-dev libpulse-dev libpipewire-0.3-dev \
  libuchardet-dev libarchive-dev libjpeg-dev liblcms2-dev \
  liblua5.2-dev libcurl4-openssl-dev \
  zlib1g-dev libbz2-dev liblzma-dev \
  glslang-dev glslang-tools devscripts dpkg-dev fakeroot wget equivs \
  python3-glad

cd ffmpeg-v4l2request

sudo mkdir -p /opt/v4l2player
sudo chown -R "$USER":"$USER" /opt/v4l2player

./configure \
  --prefix=/opt/v4l2player \
  --bindir=/opt/v4l2player/bin \
  --libdir=/opt/v4l2player/lib \
  --shlibdir=/opt/v4l2player/lib \
  --incdir=/opt/v4l2player/include \
  --pkgconfigdir=/opt/v4l2player/lib/pkgconfig \
  --enable-shared \
  --disable-static \
  --enable-pic \
  --enable-libdrm \
  --disable-doc \
  --disable-debug

make -j"$(nproc)"
make checkheaders
make install
export LD_LIBRARY_PATH=/opt/v4l2player/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}

/opt/v4l2player/bin/ffmpeg -version
/opt/v4l2player/bin/ffmpeg -hide_banner -hwaccels

mkdir /pkg
cd ..


# 作業ディレクトリの作成

# ソースのダウンロード
git clone \
  --branch rk3588-nv15-gpu-next \
  --single-branch \
  https://github.com/ryanfitz/mpv-rockchip.git \
  mpv-v4l2request
cd mpv-v4l2request
git clone https://code.videolan.org/videolan/libplacebo.git subprojects/libplacebo
git -C subprojects/libplacebo checkout 22ee762e8e0890fc54068beb670310f0edce7263

export PKG_CONFIG_PATH=/opt/v4l2player/lib/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}
export LD_LIBRARY_PATH=/opt/v4l2player/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}

meson setup build \
  --prefix=/opt/v4l2player \
  --libdir=lib \
  --buildtype=release \
  -Dv4l2request=enabled \
  -Dwayland=enabled \
  -Ddmabuf-wayland=enabled \
  -Ddrm=enabled \
  -Dmanpage-build=disabled

ninja -C build

LD_LIBRARY_PATH=/opt/v4l2player/lib ./build/mpv --version
LD_LIBRARY_PATH=/opt/v4l2player/lib ./build/mpv --no-config --hwdec=help

meson install -C build


cd /pkg
cp -r /opt .
mkdir DEBIAN
cat << 'EOF' > DEBIAN/control
Package: V4L2-request-ffmpegr-mpv 
Version: 1.0.0
Section: utils
Priority: optional
Architecture: arm64
Maintainer: Your Name <you@example.com>
Description: ffmpeg mpv V4L2-request package
EOF

cd /
fakeroot dpkg-deb --build pkg /


