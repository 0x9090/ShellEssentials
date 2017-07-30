#!/bin/sh
echo "Build script for CentOS 7, MariaDB, and Nginx\n"
echo "...and a bash playground - because whatever"

username=$SUDO_USER
distro=$(uname -a)
distro_code=0

if [ $(id -u) != 0 ]; then
	echo "This script must be run as root" 1>&2
	exit 1
fi

if [[ $distro == *"Debian"* ]]; then
	distro_code=1
	echo "Detected Debian - OK!"
elif [[ $distro == *"CentOS"* ]]; then
	distro_code=2
	echo "Detected CentOS - OK!"
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
	

echo "Updating and Configuring Yum / Apt"
if [ $distro_code == 1]; then
	apt update && apt upgrade -y
	apt install vim sudo unattended-upgrades iptables-persistent
elif [ $distro_code == 2]; then
	yum update -y
	yum install yum-cron -y
	#TODO add autopatching option to yum-cron config
	systemctl start yum-cron.service
	service iptables save
fi

echo "Customizing Vim"
echo "set smartindent" >> /home/$username/.vimrc
echo "set tabstop=4" >> /home/$username/.vimrc
echo "set shiftwidth=4" >> /home/$username/.vimrc
echo "set expandtab" >> /home/$username/.vimrc

exit

# not working stuff

#export PS1="\[\e[00;37m\]------------------------------------------------------------------------------\n\u@\W: \[\e[0m\]"
#alias lsa="ls -alh"
#echo "[mariadb]\nname = MariaDB\nbaseurl = http://yum.mariadb.org/10.0/centos7-amd64\ngpgkey = https://yum.mariadb.org/RPM-GPG-KEY-MariaDB\ngpgcheck = 1\npriority = 1" | tee /home/$username/test.repo
