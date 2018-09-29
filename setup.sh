#!/bin/bash
echo "Nops's Happy Shell\n"

set -e

username=$SUDO_USER
distro=$(uname -a)
distro_code=0
home_path=/home/$username
bashrc_path=$home_path/.bashrc

if [ $(id -u) != 0 ]; then
	echo "This script must be run as root" 1>&2
	exit 1
fi

echo "This script will drop active network connections, modify your home environment, and install things. "
read -p "Cool?  [Y/N]" -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
	exit
fi


if [[ $distro == *Debian* ]]; then
	distro_code=1
	echo "Detected Debian - OK!"
elif [[ $distro == *CentOS* ]]; then
	distro_code=2
	echo "Detected CentOS - OK!"
elif [[ $distro == *Darwin* ]]; then
	distro_code=3
	home_path=/Users/$username
	echo "Detected MacOS - OK!"
fi

echo "--- Configuring Firewall ---"
iptables -P INPUT DROP
iptables -F
iptables -X
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -p tcp --dport 22 -j ACCEPT
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT
	
echo "--- Updating and Configuring Yum / Apt ---"
if [[ $distro_code == 1 ]]; then
	apt update && apt upgrade -y
	apt install vim sudo aptitude unattended-upgrades -y
	echo iptables-persistent iptables-persistent/autosave_v4 boolean true | sudo debconf-set-selections
	echo iptables-persistent iptables-persistent/autosave_v6 boolean true | sudo debconf-set-selections
	apt install iptables-persistent -y
elif [[ $distro_code == 2 ]]; then
	yum update -y
	yum install vim yum-cron -y
	#TODO add autopatching option to yum-cron config
	systemctl start yum-cron.service
	service iptables save
elif [[ $distro_code == 3 ]]; then
	/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

echo "Customizing Vim"
rm $home_path/.vimrc
echo "set smartindent" >> $home_path/.vimrc
echo "set tabstop=4" >> $home_path/.vimrc
echo "set shiftwidth=4" >> $home_path/.vimrc
echo "set softtabstop=4" >> $home_path/.vimrc
echo "set autoindent" >> $home_path/.vimrc
echo "set expandtab" >> $home_path/.vimrc
echo "set showcmd" >> $home_path/.vimrc
echo "set ruler" >> $home_path/.vimrc
echo "set backspace=indent,eol,start" >> $home_path/.vimrc
echo "syntax on" >> $home_path/.vimrc

echo "Customizing Bash"
if [[ $distro_code == 3 ]]; then
	bashrc_path = $home_path/.bash_profile
else
rm $bashrc_path
echo "export PS1=\"\\[\\e[00;37m\\]---------------------------------------------\\n\\u@\\W: \\[\\e[0m\\]\"" >> $bashrc_path
echo "alias ls=\"ls --color\"" >> $bashrc_path
echo "alias lsa=\"ls -alh --color\"" >> $bashrc_path
if [[ ! $distro_code == 3 ]]; then
	rm $home_path/.inputrc
	echo "set completion-ignore-case on" >> $home_path/.inputrc
	rm /root/.bashrc
	echo "export PS1=\"\\[\\e[00;37m\\]---------------------------------------------\\n\\[\\e[0m\\]\\[\\e[00;31m\\]\\u\\[\\e[0m\\]\\[\\e[00;37m\\]@\\W: \\[\\e[0m\\]\"" >> /root/.bashrc
fi

exit

# todo stuff
#echo "[mariadb]\nname = MariaDB\nbaseurl = http://yum.mariadb.org/10.0/centos7-amd64\ngpgkey = https://yum.mariadb.org/RPM-GPG-KEY-MariaDB\ngpgcheck = 1\npriority = 1" | tee /home/$username/test.repo
