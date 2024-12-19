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

# Install Apache
echo -e '\n\nInstalling git ... \n'

echo $password | sudo -S dnf install -y vim bash-completion curl wget telnet
wait

echo $password | sudo -S setenforce 0
wait

echo $password | sudo -S sed -i 's/^SELINUX=.*/SELINUX=permissive/g' /etc/selinux/config
wait

echo $password | sudo -S  dnf -y install httpd
wait

echo $password | sudo -S systemctl start httpd && echo $password | sudo -S systemctl enable httpd
wait

echo $password | sudo -S firewall-cmd --add-service={http,https} --permanent
wait

echo $password | sudo -S firewall-cmd --reload
wait

echo $password | sudo -S dnf -y install php-cli phpunit composer php-fpm php-mysqlnd php-zip php-devel php-gd php-mcrypt php-mbstring php-curl php-xml php-pear php-bcmath php-json php-php-gettext phpMyAdmin php-php-gettext
wait

echo $password | sudo -S dnf -y install mariadb-server
wait

sudo systemctl start mariadb &&
sudo systemctl enable mariadb

# Anydesk

echo $password | sudo tee /etc/yum.repos.d/AnyDesk-Fedora.repo <<EOF
[anydesk]
name=AnyDesk Fedora - stable
baseurl=http://rpm.anydesk.com/centos/x86_64/
gpgcheck=0
repo_gpgcheck=0
gpgkey=https://keys.anydesk.com/repos/RPM-GPG-KEY
EOF
echo $password | sudo -S dnf makecache
echo $password | sudo -S dnf -y install redhat-lsb-core anydesk

# Install PNPM

wget -qO- https://get.pnpm.io/install.sh | sh -
wait


echo -e  "Дальше нужно запустить команду 'sudo mysql_secure_installation' \n"
echo -e  "И пройти установку. Кроме пароля на все можно нажать Y\n\n"

echo -e  "Позже нужно изменить строку в Require local на Require all granted '/etc/httpd/conf.d/phpMyAdmin.conf'\n"


