#!/bin/bash

echo "Начало выполнения скрипта"

# Запрос пароля sudo
echo "Введите пароль для sudo:"
read -s password
# $password = 135531

clear

# Download Drivers
echo $password | sudo -S dnf -y install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

echo -e 'Download Drivers \n'
echo $password | sudo -S dnf -y swap ffmpeg-free ffmpeg --allowerasing
wait

echo $password | sudo -S dnf -y swap mesa-va-drivers mesa-va-drivers-freeworld
wait

echo $password | sudo -S dnf -y swap mesa-vdpau-drivers mesa-vdpau-drivers-freeworld
wait

echo $password | sudo -S dnf -y swap mesa-va-drivers.i686 mesa-va-drivers-freeworld.i686
wait

echo $password | sudo -S dnf -y swap mesa-vdpau-drivers.i686 mesa-vdpau-drivers-freeworld.i686
wait

echo $password | sudo -S dnf -y install libva-nvidia-driver
wait
