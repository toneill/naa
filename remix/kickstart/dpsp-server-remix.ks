# Kickstart file automatically generated by anaconda.

#version=DEVEL
install
url --url=http://test:password@10.0.0.29/fedora/linux/releases/14/Fedora/x86_64/os
lang en_AU.UTF-8
keyboard us
network --onboot yes --device eth0 --bootproto dhcp --noipv6
timezone --utc Australia/Sydney
rootpw  --iscrypted $6$8a.m05jE8wVRnTHD$83I21pm3JyikuX4X6qZGEGCGzSa1mxBl3umEolbzOxGv/xKPTTJFKy8d9OlH0z0yE83DHvflN8t37WxmAIwKs0
selinux --enforcing
authconfig --enableshadow --passalgo=sha512 --enablefingerprint
firewall --service=ssh
# The following is the partition information you requested
# Note that any partitions you deleted are not expressed
# here so unless you clear all partitions first, this is
# not guaranteed to work
clearpart --all --drives=sda
part /boot --fstype=ext4 --asprimary --size=512
part pv.8qJs0X-cWnA-2T83-R6VJ-Jwc5-7XDB-xth2Gg --grow --asprimary --size=512

volgroup fedora --pesize=32768 pv.8qJs0X-cWnA-2T83-R6VJ-Jwc5-7XDB-xth2Gg
logvol / --fstype=ext4 --name=root --vgname=fedora --grow --size=1024 --maxsize=10240
logvol /data --fstype=ext4 --name=data --vgname=fedora --grow --size=1024 --maxsize=10240
logvol /var --fstype=ext4 --name=var --vgname=fedora --grow --size=1024 --maxsize=5120
logvol swap --name=swap --vgname=fedora --grow --size=1024 --maxsize=2048

bootloader --location=mbr --driveorder=sda --append="rhgb quiet" --md5pass=$1$UCcODstZ$SQu.EdskpDLfc5Scg..wN0

#Repos
repo --name="RPMFusion Free"  --baseurl=http://test:password@10.0.0.29/rpmfusion/free/fedora/releases/14/Everything/x86_64/os --cost=1000
repo --name="RPMFusion Free - Updates"  --baseurl=http://test:password@10.0.0.29/rpmfusion/free/fedora/updates/14/x86_64 --cost=1000
repo --name="RPMFusion NonFree"  --baseurl=http://test:password@10.0.0.29/rpmfusion/nonfree/fedora/releases/14/Everything/x86_64/os --cost=1000
repo --name="RPMFusion NonFree - Updates"  --baseurl=http://test:password@10.0.0.29/rpmfusion/nonfree/fedora/updates/14/x86_64 --cost=1000
repo --name="Fedora 14 - x86_64"  --baseurl=http://test:password@10.0.0.29/fedora/linux/releases/14/Everything/x86_64/os --cost=1000
repo --name="Fedora 14 - x86_64 - Updates"  --baseurl=http://test:password@10.0.0.29/fedora/linux/updates/14/x86_64 --cost=1000
repo --name="VirtualBox"  --baseurl=http://test:password@10.0.0.29/virtualbox/rpm/fedora/14/x86_64 --cost=1000
repo --name="Yum Rawhide"  --baseurl=http://test:password@10.0.0.29/yum-rawhide/fedora-14/x86_64 --cost=1000

%packages
@core
@british-support
@gnome-desktop
@online-docs
@base-x
gvfs-obexftp
gdm

%post

#copy repo file for Google Chrome into /etc/yum.repos.d/
#copy repo file for VirtualBox into /etc/yum.repos.d/
#copy repo file for Yum Rawhide into /etc/yum.repos.d/

#Need to set "exclude=AdobeReader*" in adobe repo
#Need to set "includepkgs=libdvdcss*" in atrpms repo (if we use it instead of livna, which is often unreliable)
#Need to set "clean_requirements_on_remove = 1" in /etc/yum.conf
#Copy Firefox addons to /usr/lib64/firefox-3.6/defaults/profile/extensions/


%end