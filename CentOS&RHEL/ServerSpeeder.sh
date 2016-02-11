#!/bin/bash
export PATH="$PATH:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin"
clear
echo ""
echo "#############################################################"
echo "# One click Install serverSpeeder(CentOS/RHEL)              #"
echo "# WelCome to visit: https://iforday.com/46.html             #"
echo "# Happy new year!                                           #"
echo "# 2016/2/10                                                 #"
echo "#############################################################"
echo ""
# 检查ROOT权限
function rootness(){
    if [[ $EUID -ne 0 ]]; then
       echo "Error:This script must be run as root!" 1>&2
       exit 1
    fi
}
# 关闭SElinux
function disable_selinux(){
if [ -s /etc/selinux/config ] && grep 'SELINUX=enforcing' /etc/selinux/config; then
    sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
    setenforce 0
fi
}
#收集KEY
echo "Please Enter Your serverSpeeder KEY:"
read key
echo "Your KEY is: $key"
get_char() 
{ 
SAVEDSTTY=`stty -g` 
stty -echo 
stty cbreak 
dd if=/dev/tty bs=1 count=1 2> /dev/null 
stty -raw 
stty echo 
stty $SAVEDSTTY 
} 
 
echo "Press any key to start...or Press Ctrl+C to cancel" 
char=`get_char` 
#安装必要工具
yum -y install python python-dev python-pip curl wget unzip  make perl unzip vim gcc gcc-c++ libstdc++-devel cc
#安装macchanger
wget http://dl.iforday.com/blog/macchanger-1.6.0.zip
unzip macchanger-1.6.0.zip
chmod +x configure
sudo ./configure
sudo make
sudo make install 
rm -rf macchanger-1.6.0.zip data doc src tools aclocal.m4 AUTHORS ChangeLog config.h.in configure configure.in depcomp install-sh macchanger.1 Makefile.am Makefile.in missing NEWS README
#生成文件		
        cat << _EOF_ >mac.py
S='${key}'
m4=(int(S[4:6],16)-int(S[0:2],16)+int(S[8:10],16)-22)/2
m2=int(S[4:6],16)-m4-16
m0=int(S[0:2],16)-m2-10

m5=(int(S[6:8],16)-int(S[2:4],16)+int(S[10:12],16)-25)/2
m1=int(S[10:12],16)-m5-19
m3=int(S[2:4],16)-m1-13

if (m0 >= 0 and m1 >= 0 and m2 >= 0 and m3 >= 0 and m4 >= 0 and m5 >= 0):
        print '%02x:%02x:%02x:%02x:%02x:%02x'%(m0,m1,m2,m3,m4,m5)
else:
        MAC0 = '%02x:%02x:%02x:%02x:%02x:%02x'%(m0%256,m1%256,m2%256,m3%256,m4%256,m5%256)
        MAC = MAC0.replace(':','')
        S2 = '%02X%02X%02X%02X%02X%02X%02X%02X'%((int(MAC[0:2],16)+int(MAC[4:6],16)+10)%256,(int(MAC[2:4],16)+int(MAC[6:8],16)+13)%256,(int(MAC[4:6],16)+int(MAC[8:10],16)+16)%256,(int(MAC[6:8],16)+int(MAC[10:12],16)+19)%256,(int(MAC[8:10],16)+int(MAC[0:2],16)+16)%256,(int(MAC[10:12],16)+int(MAC[2:4],16)+19)%256,(int(MAC[0:2],16)+int(MAC[4:6],16)+22)%256,(int(MAC[2:4],16)+int(MAC[6:8],16)+26)%256)
        if (S.lower() == S2.lower()):
                print MAC0
        else:
                print 'error '
_EOF_
#查询MAC,IP
newmac=$(python mac.py)
oldmac=$(ifconfig |grep eth0|awk '{print $5}')
IP=$(curl -s -4 icanhazip.com)
echo Your oldmac is:$oldmac
echo Your newmac is:$newmac
echo Your IP is:$IP
rm -rf mac.py
#修改MAC
ifdown eth0
macchanger eth0 -m $newmac
#安装锐速
echo -------------------------------------------------------
echo Begin to install serverSpeeder,Please wait for a minute
echo -------------------------------------------------------
# Copyright (C) 2015 AppexNetworks
# Author:	Len
# Date:		Aug, 2015
ROOT_PATH=/serverspeeder
SHELL_NAME=serverSpeeder.sh
PRODUCT_NAME=ServerSpeeder
PRODUCT_ID=serverSpeeder
host=dl.serverspeeder.com

[ -w / ] || {
	echo "You are not running $PRODUCT_NAME Installer as root. Please rerun as root"
	exit 1
}

if [ $# -ge 1 -a "$1" == "uninstall" ]; then
	acceExists=$(ls $ROOT_PATH/bin/acce* 2>/dev/null)
    [ -z "$acceExists" ] && {
        echo "$PRODUCT_NAME is not installed!"
        exit
    }
    $ROOT_PATH/bin/$SHELL_NAME uninstall
    exit
fi

# Locate which
WHICH=`which ls 2>/dev/null`
[ $? -gt 0 ] && {
	echo '"which" not found, please install "which" using "yum install which" or "apt-get install which" according to your linux distribution'
	exit 1
}

IPCS=`which ipcs 2>/dev/null`
[  $? -eq 0 ] && {
    maxSegSize=`ipcs -l | awk -F= '/max seg size/ {print $2}'`
    maxTotalSharedMem=`ipcs -l | awk -F= '/max total shared memory/ {print $2}'`
    [ $maxSegSize -eq 0 -o $maxTotalSharedMem -eq 0 ] && {
        echo "$PRODUCT_NAME needs to use shared memory, please configure the shared memory according to the following link: "
        echo "http://$host/user.do?m=qa#4.4"
        exit 1
    }
}

addStartUpLink() {
	grep -E "CentOS|Fedora|Red.Hat" /etc/issue >/dev/null
	[ $? -eq 0 ] && {
		ln -sf $ROOT_PATH/bin/$SHELL_NAME /etc/rc.d/init.d/$PRODUCT_ID
		[ -z "$boot" -o "$boot" = "n" ] && return
		CHKCONFIG=`which chkconfig`
		if [ -n "$CHKCONFIG" ]; then
			chkconfig --add $PRODUCT_ID >/dev/null
		else
			ln -sf /etc/rc.d/init.d/$PRODUCT_ID /etc/rc.d/rc2.d/S20$PRODUCT_ID
			ln -sf /etc/rc.d/init.d/$PRODUCT_ID /etc/rc.d/rc3.d/S20$PRODUCT_ID
			ln -sf /etc/rc.d/init.d/$PRODUCT_ID /etc/rc.d/rc4.d/S20$PRODUCT_ID
			ln -sf /etc/rc.d/init.d/$PRODUCT_ID /etc/rc.d/rc5.d/S20$PRODUCT_ID
		fi
	}
	grep "SUSE" /etc/issue >/dev/null
	[ $? -eq 0 ] && {
		ln -sf $ROOT_PATH/bin/$SHELL_NAME /etc/rc.d/$PRODUCT_ID
		[ -z "$boot" -o "$boot" = "n" ] && return
		CHKCONFIG=`which chkconfig`
		if [ -n "$CHKCONFIG" ]; then
			chkconfig --add $PRODUCT_ID >/dev/null
		else
			ln -sf /etc/rc.d/$PRODUCT_ID /etc/rc.d/rc2.d/S06$PRODUCT_ID
			ln -sf /etc/rc.d/$PRODUCT_ID /etc/rc.d/rc3.d/S06$PRODUCT_ID
			ln -sf /etc/rc.d/$PRODUCT_ID /etc/rc.d/rc5.d/S06$PRODUCT_ID
		fi
	}
	grep -E "Ubuntu|Debian" /etc/issue >/dev/null
	[ $? -eq 0 ] && {
		ln -sf $ROOT_PATH/bin/$SHELL_NAME /etc/init.d/$PRODUCT_ID
		[ -z "$boot" -o "$boot" = "n" ] && return 
		ln -sf /etc/init.d/$PRODUCT_ID /etc/rc2.d/S03$PRODUCT_ID
		ln -sf /etc/init.d/$PRODUCT_ID /etc/rc3.d/S03$PRODUCT_ID
		ln -sf /etc/init.d/$PRODUCT_ID /etc/rc5.d/S03$PRODUCT_ID
	}
	ln -sf $ROOT_PATH/etc/config /etc/$PRODUCT_ID.conf
}

[ -d $ROOT_PATH/bin ] || mkdir -p $ROOT_PATH/bin
[ -d $ROOT_PATH/etc ] || mkdir -p $ROOT_PATH/etc
[ -d $ROOT_PATH/log ] || mkdir -p $ROOT_PATH/log
cd $(dirname $0)
dt=`date +%Y-%m-%d_%H-%M-%S`
[ -f $ROOT_PATH/etc/config ] && mv -f $ROOT_PATH/etc/config $ROOT_PATH/etc/.config_$dt.bak

cp -f apxfiles/bin/* $ROOT_PATH/bin/
cp -f apxfiles/etc/* $ROOT_PATH/etc/
chmod +x $ROOT_PATH/bin/*

[ -f $ROOT_PATH/etc/.config_$dt.bak ] && {
	while read _line; do
		item=$(echo $_line | awk -F= '/^[^#]/ {print $1}')
		val=$(echo $_line | awk -F= '/^[^#]/ {print $2}' | sed 's#\/#\\\/#g')
		[ -n "$item" -a "$item" != "accpath" -a "$item" != "apxexe" -a "$item" != "apxlic" -a "$item" != "installerID" -a "$item" != "email" -a "$item" != "serial" ] && {
			if [ -n "$(grep $item $ROOT_PATH/etc/config)" ]; then
				sed -i "s/^$item=.*/$item=$val/" $ROOT_PATH/etc/config
			else
				sed -i "/^engineNum=.*/a$item=$val" $ROOT_PATH/etc/config
			fi
		}
	done<$ROOT_PATH/etc/.config_$dt.bak
}

[ -f apxfiles/expiredDate ] && {
    echo -n "Expired date: "
    cat apxfiles/expiredDate
    echo
}

echo "Installation done!"
echo
 
# Set acc inf
echo ----------------------------------------------------------------------------------
echo You are about to be asked to enter information that will be used by $PRODUCT_NAME,
echo there are several fields and you can leave them blank,
echo 'for all fields there will be a default value.'
echo ----------------------------------------------------------------------------------
#echo -n "Enter your accelerated interface(s) [eth0]: "
#read accif
#echo -n "Enter your outbound bandwidth [1000000 kbps]: "
#read wankbps
#echo -n "Enter your inbound bandwidth [1000000 kbps]: "
#read waninkbps

#echo -e "\033[30;40;1m"
#echo 'Notice:After set shorttRtt-bypass value larger than 0,' 
#echo 'it will bypass(not accelerate) all first flow from same 24-bit'
#echo 'network segment and the flows with RTT lower than the shortRtt-bypass value'
#echo -e "\033[0m"
#echo -n "Configure shortRtt-bypass [0 ms]: "
#read shortRttMS
[ -z "0" ] || [ -n "0" ] && shortRttMS=0

[ -n "eth0" ] && sed -i "s/^accif=.*/accif=\"$accif\"/" $ROOT_PATH/etc/config
[ -n "1000000" ] && {
	wankbps=$(echo 1000000 | tr -d "[:alpha:][:space:]")
	sed -i "s/^wankbps=.*/wankbps=\"1000000\"/" $ROOT_PATH/etc/config
}
[ -n "1000000" ] && {
	waninkbps=$(echo 1000000 | tr -d "[:alpha:][:space:]")
	sed -i "s/^waninkbps=.*/waninkbps=\"1000000\"/" $ROOT_PATH/etc/config
}
[ -n "$shortRttMS" ] && {
	shortRttMS=$(echo 0 | tr -d "[:alpha:][:space:]")
	sed -i "s/^shortRttMS=.*/shortRttMS=\"0\"/" $ROOT_PATH/etc/config
}

while [ "y" != 'y' -a "y" != 'y' -a "y" != 'Y' -a "y" != 'y'  ]; do
	#echo -n "Auto load $PRODUCT_NAME on linux start-up? [n]:"
	#read boot
	[ -z "y" ] && boot=y
done
[ "y" = "y" ] && boot=y 
addStartUpLink

while [ "y" != 'y' -a "y" != 'y' -a "y" != 'Y' -a "y" != 'y'  ]; do
	#echo -n "Run $PRODUCT_NAME now? [y]:"
	#read startNow
	[ -z "y" ] && startNow=y
done

[ "y" = "y" -o "y" = "Y" ] && {
	$ROOT_PATH/bin/$SHELL_NAME stop >/dev/null 2>&1
	$ROOT_PATH/bin/$SHELL_NAME start 
}
#修改回MAC
ifdown eth0
macchanger eth0 -m $oldmac
ifup eth0
/serverspeeder/bin/serverSpeeder.sh status
echo ---------------------------------------------
echo Enjoy! Have a good time!
echo WelCome to visit: https://iforday.com/46.html
echo ---------------------------------------------