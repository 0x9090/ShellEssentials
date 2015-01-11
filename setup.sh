#!/bin/sh
echo "Build script for CentOS 7, MariaDB, and Nginx\n"

username="nops"

if [ $(id -u) != 0 ]; then
	echo "This script must be run as root" 1>&2
	exit 1
fi

echo "Configuring Firewall"
iptables -P INPUT ACCEPT
iptables -F
iptables -X
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -p tcp --dport 22 -j ACCEPT
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

echo "Updating and Configuring Yum"
yum update -y
yum install yum-cron -y

echo "Customizing Vim" >> /home/$username/.vimrc
echo "set smartindent"

echo "[mariadb]\nname = MariaDB\nbaseurl = http://yum.mariadb.org/10.0/centos7-amd64\ngpgkey = https://yum.mariadb.org/RPM-GPG-KEY-MariaDB\ngpgcheck = 1\npriority = 1" | tee /home/alawrence/test.repo

echo
