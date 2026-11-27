#!/bin/bash

set -eE
trap 'echo Error: in $0 on line $LINENO' ERR

if [ "$(id -u)" -ne 0 ]; then 
    echo "Please run as root"
    exit 1
fi
suite=resolute
Uri="http://ftp.udx.icscoe.jp/Linux/ubuntu-ports/"
#Uri="http://ports.ubuntu.com/ubuntu-ports
# ディスクイメージを作成するために必要なツールをインストール
sudo apt-get update && sudo apt-get -y install  debootstrap systemd-container 

#Bootstrap the system
rm -rf $1
mkdir $1
chroot_dir=$1
mem_size=`free --giga|grep Mem|awk '{print $2}'`
if [ $mem_size -gt 13 ]; then
	mount -t tmpfs -o size=12G tmpfs $chroot_dir
fi

	debootstrap $suite arm64 $Uri

export DEBIAN_FRONTEND=noninteractive
export DEBCONF_NONINTERACTIVE_SEEN=true
export  LC_ALL=C
export  LC_CTYPE=C
export  LANGUAGE=C
export  LANG=C 

#Setup DNS
echo "127.0.0.1 localhost" > $1/etc/hosts
echo "127.0.0.1 ubuntu-desktop" > $1/etc/hosts
echo "nameserver 8.8.8.8" > $1/etc/resolv.conf
echo "nameserver 8.8.4.4" >> $1/etc/resolv.conf

#sources.list setup
rm $1/etc/hostname
echo "ubuntu-desktop" > $1/etc/hostname
{
echo "Types: deb"
echo "URIs: $Uri"
echo "Suites: $suite $suite-updates $suite-backports"
echo "Components: main universe restricted multiverse"
echo "Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg"
echo ""
echo "## Ubuntu security updates. Aside from URIs and Suites,"
echo "## this should mirror your choices in the previous section."
echo "Types: deb"
echo "URIs: $Uri"
echo "Suites: $suite-security"
echo "Components: main universe restricted multiverse"
echo "Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg"
} > $1/etc/apt/sources.list.d/ubuntu.sources
rm -f $1/etc/apt/sources.list

echo "\n##################	systemd-nspawn	START	#######################\n"

systemd-nspawn -D $1 --resolv-conf=replace-host -E DEBIAN_FRONTEND=noninteractive --as-pid2 sudo apt-get clean
systemd-nspawn -D $1 --resolv-conf=replace-host -E DEBIAN_FRONTEND=noninteractive --as-pid2 sudo apt-get update
systemd-nspawn -D $1 --resolv-conf=replace-host -E DEBIAN_FRONTEND=noninteractive --as-pid2 sudo apt-get -y upgrade
systemd-nspawn -D $1 --resolv-conf=replace-host -E DEBIAN_FRONTEND=noninteractive --as-pid2 sudo apt-get -y dist-upgrade
systemd-nspawn -D $1 --resolv-conf=replace-host -E DEBIAN_FRONTEND=noninteractive --as-pid2 sudo apt-get -y install build-essential \
flex libssl-dev bc rsync kmod cpio xz-utils fakeroot python3 bison \
python-is-python3 debhelper python3-pyelftools python3-setuptools \
python3-pkg-resources swig libfdt-dev libpython3-dev \
git fakeroot libssl-dev libelf-dev libgnutls28-dev 


#systemd-nspawn -D $1 --resolv-conf=replace-host -E DEBIAN_FRONTEND=noninteractive --as-pid2 sudo apt-get -y install meson ninja-build pkgconf pkgconf-bin python3-mako \
#libunwind-dev



	cp ffmpeg_ubuntu.sh $1 && chmod +x $1/ffmpeg_ubuntu.sh
	systemd-nspawn -D $1 --resolv-conf=replace-host -E DEBIAN_FRONTEND=noninteractive --as-pid2 /ffmpeg_ubuntu.sh
cp $1/*.deb  .

#if [ $mem_size -gt 13 ]; then
#	umount $chroot_dir
#	sleep 2
#fi
