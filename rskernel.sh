#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#=======================================================#
# One-click Change Kernel to Adapt LotServer for CentOS #
# Github: https://github.com/uxh/awesome-linux-tools    #
# Author: www.banwagongzw.com && www.vultrcn.com        #
#=======================================================#

#Version
uxhshellversion="3.0.0"

#Basic url
uxhbasicurl="https://github.com/uxh/Linux-NetSpeed-Backup/raw/master"

#Default
uxhrelease=""
uxhversion=""
uxhbit=""
uxhvirt=""
uxhkernel=""

#Level
uxherror="[\033[0;31mERROR\033[0m]"
uxhinfo="[\033[0;32mINFO\033[0m]"
uxhwarn="[\033[0;33mWARN\033[0m]"

#Check root
[[ $EUID -ne 0 ]] && echo -e "${uxherror} This script must be run as root!" && exit 1

#Check release
function check_release(){
    if [ -f /etc/redhat-release ]; then
        uxhrelease="centos"
    elif cat /etc/issue | grep -iqE "centos|red hat|redhat"; then
        uxhrelease="centos"
    elif cat /etc/issue | grep -iqE "debian"; then
        uxhrelease="debian"
    elif cat /etc/issue | grep -iqE "ubuntu"; then
        uxhrelease="ubuntu"
    elif cat /proc/version | grep -iqE "centos|red hat|redhat"; then
        uxhrelease="centos"
    elif cat /proc/version | grep -iqE "debian"; then
        uxhrelease="debian"
    elif cat /proc/version | grep -iqE "ubuntu"; then
        uxhrelease="ubuntu"
    else
        uxhrelease="none"
    fi

    if [[ "${uxhrelease}" != "centos" ]]; then
        echo -e "${uxherror} This script only support CentOS!"
        exit 1
    fi
}

#Check version
function check_version(){
    if [ -s /etc/redhat-release ]; then
        uxhversion=$(grep -oE "[0-9.]+" /etc/redhat-release | cut -d . -f 1)
    else
        uxhversion=$(grep -oE "[0-9.]+" /etc/issue | cut -d . -f 1)
    fi

    if [[ "${uxhrelease}" == "centos" ]]; then
        if [[ ${uxhversion} -lt 6 ]] || [[ ${uxhversion} -gt 7 ]]; then
            echo -e "${uxherror} This script only support CentOS 6~7!"
            exit 1
        fi
    elif [[ "${uxhrelease}" == "debian" ]]; then
        if [[ ${uxhversion} -lt 7 ]] || [[ ${uxhversion} -gt 9 ]]; then
            echo -e "${uxherror} This script only support Debian 7~9!"
            exit 1
        fi
    elif [[ "${uxhrelease}" == "ubuntu" ]]; then
        if [[ ${uxhversion} -lt 12 ]] || [[ ${uxhrelease} -gt 18 ]]; then
            echo -e "${uxherror} This script only support Ubuntu 12~18!"
            exit 1
        fi
    fi
}

#Check virt
function check_virt(){
    if [[ "${uxhrelease}" == "centos" ]]; then
        yum install virt-what -y
    elif [[ "${uxhrelease}" == "debian" ]] || [[ "${uxhrelease}" == "ubuntu" ]]; then
        apt-get install virt-what -y
    fi

    uxhvirt=$(virt-what)

    if [[ "${uxhvirt}" != "kvm" ]]; then
        echo -e "${uxherror} This script only support KVM VPS!"
        exit 1
    fi
}

#Check bit
function check_bit(){
    local value=$(uname -m)

    if [[ "${value}" == "x86_64" ]]; then
        uxhbit="x64"
    else
        echo -e "${uxherror} This script only support x86_64 OS!"
        exit 1
    fi
}

#Check status
function check_status(){
    if [[ "${uxhrelease}" == "centos" ]]; then
        if uname -r | grep -iqE "2.6.32-504|4.11.2-1.el7.elrepo.x86_64"; then
            echo -e "${uxhinfo} Kernel is $(uname -r), it does not need to change."
            exit 0
        elif [[ ${uxhversion} -eq 6 ]]; then
            uxhkernel="2.6.32-504"
        elif [[ ${uxhversion} -eq 7 ]]; then
            uxhkernel="4.11.2-1"
        fi
    elif [[ "${uxhrelease}" == "debian" ]]; then
        if uname -r | grep -iqE "3.2.0-4-amd64|3.16.0-4-amd64|4.9.0-4-amd64"; then
            echo -e "${uxhinfo} Kernel is $(uname -r), it does not need to change."
            exit 0
        elif [[ ${uxhversion} -eq 7 ]]; then
            uxhkernel="3.2.0-4"
        elif [[ ${uxhversion} -eq 8 ]]; then
            uxhkernel="3.16.0-4"
        elif [[ ${uxhversion} -eq 9 ]]; then
            uxhkernel="4.9.0-4"
        fi
    elif [[ "${uxhrelease}" == "ubuntu" ]]; then
        if uname -r | grep -iqE "3.16.0-77|4.8.0-36|4.15.0-30"; then
            echo -e "${uxhinfo} Kernel is $(uname -r), it does not need to change."
            exit 0
        elif [[ ${uxhversion} -eq 14 ]]; then
            uxhkernel="3.16.0-77"
        elif [[ ${uxhversion} -eq 16 ]]; then
            uxhkernel="4.8.0-36"
        elif [[ ${uxhversion} -eq 18 ]]; then
            uxhkernel="4.15.0-30"
        fi
    fi
}

#Install ca
function install_ca(){
    if [[ "${uxhrelease}" == "centos" ]]; then
        yum install ca-certificates -y
        update-ca-trust force-enable
    elif [[ "${uxhrelease}" == "debian" ]] || [[ "${uxhrelease}" == "ubuntu" ]]; then
        apt-get install ca-certificates -y
        update-ca-certificates
    fi
}

#Disable selinux
function disable_selinux() {
    if [ -s /etc/selinux/config ] && grep "SELINUX=enforcing" /etc/selinux/config; then
        sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
        setenforce 0
    fi
}

#Install kernel
function install_kernel(){
    if [[ "${uxhrelease}" == "centos" ]]; then
        if [[ ${uxhversion} -eq 6 ]] || [[ ${uxhversion} -eq 7 ]]; then
            rpm --import ${uxhbasicurl}/lotserver/${uxhrelease}/RPM-GPG-KEY-elrepo.org
            yum remove kernel-firmware -y
            yum install ${uxhbasicurl}/lotserver/${uxhrelease}/${uxhversion}/${uxhbit}/kernel-firmware-${uxhkernel}.rpm -y
            yum install ${uxhbasicurl}/lotserver/${uxhrelease}/${uxhversion}/${uxhbit}/kernel-${uxhkernel}.rpm -y
            yum remove kernel-headers -y
            yum install ${uxhbasicurl}/lotserver/${uxhrelease}/${uxhversion}/${uxhbit}/kernel-headers-${uxhkernel}.rpm -y
            yum install ${uxhbasicurl}/lotserver/${uxhrelease}/${uxhversion}/${uxhbit}/kernel-devel-${uxhkernel}.rpm -y
            if [[ ${uxhversion} -eq 6 ]]; then
                grubby --info=ALL | awk -F= '$1=="kernel" {print i++ " : " $2}' | grep -iqE '2.6.32-504'
                [[ $? -ne 0 ]] && echo -e "${uxherror} Install kernel failed!" && exit 1
                local value=$(cat /boot/grub/grub.conf | awk '$1=="title" {print i++ " : " $NF}' | grep '2.6.32-504' | awk '{print $1}')
                sed -i "s/^default=.*/default=${value}/g" /boot/grub/grub.conf
            else
                grubby --info=ALL | awk -F= '$1=="kernel" {print i++ " : " $2}' | grep -iqE '4.11.2-1.el7.elrepo.x86_64'
                [[ $? -ne 0 ]] && echo -e "${uxherror} Install kernel failed!" && exit 1
                grub2-set-default $(awk -F\' '$1=="menuentry " {print i++ " : " $2}' /etc/grub2.cfg | grep 'CentOS Linux (4.11.2-1.el7.elrepo.x86_64) 7 (Core)' | awk '{print $1}')
            fi
        fi
        echo -e "---------------------------------------------------------------------------"
        echo -e "${uxhinfo} Success! Your server will reboot in 10s... or Press Ctrl+C to cancel"
        echo -n  "10" && sleep 1 && echo -n "  9" && sleep 1 && echo -n "  8" && sleep 1 && echo -n "  7" && sleep 1 && echo -n "  6" && sleep 1 && echo -n "  5" && sleep 1 && echo -n "  4" && sleep 1 && echo -n "  3" && sleep 1 && echo -n "  2" && sleep 1 && echo "  1" && sleep 1
        echo -e "${uxhinfo} Reboot now..."
        reboot
    elif [[ "${uxhrelease}" == "debian" ]] || [[ "${uxhrelease}" == "ubuntu" ]]; then
        apt-get install wget -y
        bash <(wget -qO- "${uxhbasicurl}/Debian_Kernel.sh")
    fi
}


#Main
clear
echo -e "#===============================================================#"
echo -e "# One-click Change Kernel to Adapt LotServer for CentOS (${uxhshellversion}) #"
echo -e "# Github: https://github.com/uxh/awesome-linux-tools            #"
echo -e "# Author: www.banwagongzw.com && www.vultrcn.com                #"
echo -e "#===============================================================#"
echo -e ""
echo -e "Press Enter to continue... or Press Ctrl+C to cancel"
read -n 1

check_release
check_version
check_virt
check_bit
check_status
disable_selinux
install_ca
install_kernel
