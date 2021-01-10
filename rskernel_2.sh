#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#===============================================================#
# One-click Change Kernel to Adapt Serverspeeder for CentOS 6/7 #
# Github: https://github.com/uxh/awesome-linux-tools            #
# Author: www.banwagongzw.com && www.vultrcn.com                #
#===============================================================#

#Color
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

#Check root
[[ $EUID -ne 0 ]] && echo -e "${red}This script must be run as root!${plain}" && exit 1

#Check system
function check_release(){
    local value=$1
    local release="none"

    if [ -f /etc/redhat-release ]; then
        release="centos"
    elif grep -qi "centos|red hat|redhat" /etc/issue; then
        release="centos"
    elif grep -qi "centos|red hat|redhat" /proc/version; then
        release="centos"
    elif grep -qi "centos|red hat|redhat" /etc/*-release; then
        release="centos"
    fi

    if [[ ${value} == ${release} ]]; then
        return 0
    else
        return 1
    fi
}

#Check virt
function check_virt(){
    yum install -y virt-what

    local value=$1
    local virt=$(virt-what)

    if [ "${value}" == "${virt}" ]; then
        return 0
    else
        return 1
    fi
}

#Check centos main version
function check_centos_main_version() {
    local value=$1
    local version="0.0.0"

    if [ -s /etc/redhat-release ]; then
        version=$(grep -Eo "[0-9.]+" /etc/redhat-release)
    else
        version=$(grep -Eo "[0-9.]+" /etc/issue)
    fi

    local mainversion=${version%%.*}

    if [ ${value} -eq ${mainversion} ]; then
        return 0
    else
        return 1
    fi
}

#Start information
function start(){
    clear
    echo "#====================================================================#"
    echo "# One-click Change Kernel to Adapt Serverspeeder for CentOS 6/7 v2.2 #"
    echo "# Github: https://github.com/uxh/awesome-linux-tools                 #"
    echo "# Author: www.banwagongzw.com && www.vultrcn.com                     #"
    echo "#====================================================================#"
    echo ""
    echo "Press Enter to continue...or Press Ctrl+C to cancel"
    read -n 1
}

#Main
if [ -s /etc/selinux/config ] && grep "SELINUX=enforcing" /etc/selinux/config; then
    sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
    setenforce 0
fi
if check_release centos; then
    if check_virt kvm; then
        start
        if check_centos_main_version 6; then
            echo -e "[${green}INFO${plain}] System OS is CentOS6. Processing..."
            echo -e "-------------------------------------------"
            rpm -ivh https://filedown.me/Linux/Kernel/kernel-firmware-2.6.32-504.3.3.el6.noarch.rpm
            rpm -ivh https://filedown.me/Linux/Kernel/kernel-2.6.32-504.3.3.el6.x86_64.rpm --force
            if [ $? -eq 0 ]; then
                number=$(cat /boot/grub/grub.conf | awk '$1=="title" {print i++ " : " $NF}' | grep '2.6.32-504' | awk '{print $1}')
                sed -i "s/^default=.*/default=$number/g" /boot/grub/grub.conf
                echo -e "-------------------------------------------"
                echo -e "[${green}INFO${plain}] Success! Your server will reboot in 3s..."
                sleep 1
                echo -e "[${green}INFO${plain}] Success! Your server will reboot in 2s..."
                sleep 1
                echo -e "[${green}INFO${plain}] Success! Your server will reboot in 1s..."
                sleep 1
                echo -e "[${green}INFO${plain}] Reboot..."
                reboot
            else
                echo -e "[${red}ERROR${plain}] Change kernel failed!"
                exit 1
            fi
        elif check_centos_main_version 7; then
            echo -e "[${green}INFO${plain}] System OS is CentOS7. Processing..."
            echo -e "-------------------------------------------"
            rpm -ivh https://filedown.me/Linux/Kernel/kernel-3.10.0-229.1.2.el7.x86_64.rpm --force
            if [ $? -eq 0 ]; then
                grub2-set-default `awk -F\' '$1=="menuentry " {print i++ " : " $2}' /etc/grub2.cfg | grep '(3.10.0-229.1.2.el7.x86_64) 7 (Core)' | awk '{print $1}'`
                echo -e "-------------------------------------------"
                echo -e "[${green}INFO${plain}] Success! Your server will reboot in 3s..."
                sleep 1
                echo -e "[${green}INFO${plain}] Success! Your server will reboot in 2s..."
                sleep 1
                echo -e "[${green}INFO${plain}] Success! Your server will reboot in 1s..."
                sleep 1
                echo -e "[${green}INFO${plain}] Reboot..."
                reboot
            else
                echo -e "[${red}ERROR${plain}] Change kernel failed!"
                exit 1
            fi
        elif check_centos_main_version 8; then
            echo -e "[${yellow}WARNNING${plain}] This script only support CentOS6/7!"
            exit 1
        fi
    else
        echo -e "[${yellow}WARNNING${plain}] This script only support KVM!"
        exit 1
    fi
else
    echo -e "[${yellow}WARNNING${plain}] This script only support CentOS!"
    exit 1
fi
