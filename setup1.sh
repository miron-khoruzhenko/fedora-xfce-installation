#!/bin/bash

echo "Начало выполнения скрипта"

# Запрос пароля sudo
echo "Введите пароль для sudo:"
read -s password
# $password = 135531

clear

# Update System
echo -e 'Updating system \n'
echo $password | sudo -S dnf update -y
wait

echo -e 'Upgrading system \n'
echo $password | sudo -S dnf upgrade -y 
wait

# Install git
echo -e '\n\nInstalling git ... \n'

echo $password | sudo -S dnf install -y git
wait

# Setup git config
echo -e '\n\nSetup git config ... \n'

echo git config --global init.defaultBranch master
echo git config --global user.email "mironkhoruzhenko@gmail.com"
echo git config --global user.name "Miron Khoruzhenko"
echo git config --global alias.st status
wait

# Install curl
echo -e '\n\nInstalling curl ... \n'

echo $password | sudo -S dnf install -y curl
wait

# Install pasystray
echo -e '\n\nInstalling pasystray ... \n'

echo $password | sudo -S dnf install -y pasystray
wait

# Install zsh
echo -e '\n\nInstalling zsh ... \n'

echo $password | sudo -S dnf install -y zsh
wait

# Install Snap
echo -e '\n\nInstalling snapd ... \n'

echo $password | sudo -S dnf install -y snapd
wait

echo $password | sudo -S ln -s /var/lib/snapd/snap /snap
wait

# Install VSCode
echo -e '\n\nInstalling VSCode ... \n'

echo $password | sudo -S rpm --import https://packages.microsoft.com/keys/microsoft.asc
echo $password | sudo -S sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
echo $password | sudo -S dnf install code -y
wait

# Install Telegram
echo -e '\n\nInstalling Telegram ... \n'

echo $password | sudo -S snap install telegram-desktop
wait

# Install Notion
echo -e '\n\nInstalling Notion ... \n'

echo $password | sudo -S snap install notion-snap-reborn
wait

# Install Trello
echo -e '\n\nInstalling Trello ... \n'

echo $password | sudo -S snap install trello-desktop
wait

# Install NodeJS
echo -e '\n\nInstalling nodejs ... \n'

echo $password | sudo -S dnf install -y nodejs
wait

# Install pip
echo -e '\n\nInstalling pip ... \n'

echo $password | sudo -S dnf install -y pip
wait

# Install Audio and Video decoder plugin
echo -e '\n\nInstalling mmpeg ... \n'

echo $password | sudo -S dnf install gstreamer1-plugins-{bad-\*,good-\*,base} gstreamer1-plugin-openh264 gstreamer1-libav --exclude=gstreamer1-plugins-bad-free-devel
wait

clear

echo "Проверте работает ли аудио"
echo "Если все работает в 'Session and Startup' отключите по усмотрению: "
echo "  - dnfdragora - updater"
echo -e "  - SELinux Troubleshooter\n"

echo "Далее будет установка omz. Вам нужно будет настроить конфиг"
echo -e "Послее перезагрузите компьютер и продолжите с частью 2\n"

echo "Нажмите Enter для продолжения..."

read

sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"



