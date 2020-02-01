#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#################################################################################
#Script Console Colors - Thanks quickbox !
black=$(tput setaf 0); red=$(tput setaf 1); green=$(tput setaf 2); yellow=$(tput setaf 3);
blue=$(tput setaf 4); magenta=$(tput setaf 5); cyan=$(tput setaf 6); white=$(tput setaf 7);
bold=$(tput bold);dim=$(tput dim); underline=$(tput smul);reset_underline=$(tput rmul);
standout=$(tput smso); reset_standout=$(tput rmso); normal=$(tput sgr0);
#################################################################################

# Check if user is root
if [ $(id -u) != "0" ]; then
    echo "${red}Error: ${normal}You must be root to run this script, please use root to install."
    exit 1
fi

clear

echo "${cyan}"
cat << "EOF"
  _____                  ____                _ _               
 | ____|__ _ ___ _   _  / ___|  ___  ___  __| | |__   _____  __
 |  _| / _` / __| | | | \___ \ / _ \/ _ \/ _` | '_ \ / _ \ \/ /
 | |__| (_| \__ \ |_| |  ___) |  __/  __/ (_| | |_) | (_) >  < 
 |_____\__,_|___/\__, | |____/ \___|\___|\__,_|_.__/ \___/_/\_\
                 |___/                                         
 
EOF

echo "${normal}========================================================================="
echo "${cyan}Easy Seedbox installer - Transmission & h5ai${normal}"
echo "========================================================================="
echo "${bold}Description:${normal}"
echo " Installs Transmission and WebUI to create a simple seedbox on any"
echo " Ubuntu or Debian VPS."
echo " ${dim}Script written by ${bold}swain & WEN.${normal}"
echo "========================================================================="


# Pull IP Address
if [ "$IP" = "" ]; then
    IP=$(wget -qO- ipv4.icanhazip.com)
fi

#Set var for settingsfile.
SETTINGSFILE="/etc/transmission-daemon/settings.json"
SETTINGSFILECADDY="/etc/caddy/Caddyfile"
PHPCONF="/etc/php/7.0/fpm/pool.d/www.conf"
SUPERVISORCONF="/etc/supervisor/conf.d/caddy.conf"
H5AIINDEX="/home/downloads/_h5ai/public/index.php"


cur_dir=$(pwd)


accepted="N"
echo "Would you like to install Transmission + h5ai?:"

#read user input
read -p "(${green}Y${normal}/${red}N${normal}):" accepted

#simple way to do toupper()
accepted=$(echo "${accepted}" | tr '[:lower:]' '[:upper:]')

if [ "$accepted" = "N" ]; then
    exit
fi
echo "===============================WebUI Info====================================="
username="user"
echo "Please input your requested WebUI username for the seedbox:"
read -p "(Default user:admin):" username
if [ "$username" = "" ]; then
    username="admin"
fi
echo "==========================="
echo " Username = "${username}
echo "==========================="
pass="pass"
echo "Please input your requested WebUI password for the seedbox:"
read -p "(Default Password:pass):" pass
if [ "$pass" = "" ]; then
    pass="pass"
fi
echo "==========================="
echo " Password = "${pass}
echo "==========================="


echo "============================Starting Install=================================="
apt-get -y update
apt-get -y install software-properties-common
add-apt-repository -y ppa:ondrej/php
apt-get -y update
apt-get -y install transmission-daemon curl unzip supervisor php7.0 php7.0-fpm php7.0-xml php7.0-zip php7.0-bcmath php7.0-curl php7.0-mbstring php7.0-gd
curl https://getcaddy.com | bash -s personal 
echo "============================making directories================================"
if [ ! -d "/etc/caddy" ]; then
    mkdir /etc/caddy
    echo "/etc/caddy  [created]"
else
    echo "/etc/caddy [found]"
fi
if [ ! -d "/run/php" ]; then
    mkdir /run/php
    echo "/run/php  [created]"
else
    echo "/run/php [found]"
fi
if [ ! -d "/home/downloads" ]; then
    mkdir /home/downloads
    echo "/home/downloads  [created]"
else
    echo "/home/downloads [found]"
fi
# 2nd if
if [ ! -d "/home/downloads/watch" ]; then
    mkdir /home/downloads/watch
    echo "/home/downloads/watch [created]"
else
    echo "/home/downloads/watch [found]"
    
    #3rd if
fi
if [ ! -d "/home/downloads/incomplete" ]; then
    mkdir /home/downloads/incomplete
    echo "/home/downloads/incomplete [created]"
    
else
    echo "/home/downloads/incomplete [found]"
fi
if [ ! -d "/home/downloads/downloaded" ]; then
    mkdir /home/downloads/downloaded
    echo "/home/downloads/downloaded [created]"
else
    echo "/home/downloads/downloaded [found]"
fi
wget -O /home/downloads/h5ai.zip https://release.larsjung.de/h5ai/h5ai-0.29.2.zip
unzip -o -d /home/downloads /home/downloads/h5ai.zip

echo "============================Permissions======================================="
usermod -a -G debian-transmission root
chgrp -R debian-transmission /home/downloads
chmod -R 777 /home/downloads
chown -R debian-transmission /home/downloads
cd $cur_dir
echo "============================Updating Config==================================="

truncate -s0 $SETTINGSFILECADDY
truncate -s0 $SETTINGSFILE

# pfp-fpm part
sed -i 's#listen = /run/php/php7.0-fpm.sock#listen = 127.0.0.1:9000#g' $PHPCONF 

# caddy part
echo ${IP}':9090 {' > $SETTINGSFILECADDY
cat >> $SETTINGSFILECADDY <<- EOM
    root /home/downloads/
    gzip
    
    fastcgi / 127.0.0.1:9000 php
    rewrite  {
            if {path} ends_with /
        to {dir}/index.html {dir}/index.php /_h5ai/public/index.php
    }
}
EOM

# supervisor
cat > $SUPERVISORCONF <<- EOM
[program:caddy]

command=caddy
directory=/etc/caddy
autostart=true
startsecs=10
autorestart = true
startretries=3
user=debian-transmission
stdout_logfile_maxbytes=10MB
stdout_logfile_backups = 10
stdout_logfile = /var/log/caddylog.log
EOM

# transimssion part
cat > $SETTINGSFILE <<- EOM
{
"alt-speed-down": 50,

"alt-speed-enabled": false,

"alt-speed-time-begin": 540,

"alt-speed-time-day": 127,

"alt-speed-time-enabled": false,

"alt-speed-time-end": 1020,

"alt-speed-up": 50,

"bind-address-ipv4": "0.0.0.0",

"bind-address-ipv6": "::",

"blocklist-enabled": false,

"dht-enabled": true,

"download-dir": "/home/downloads/downloaded/",

"incomplete-dir": "/home/downloads/incomplete/",

"incomplete-dir-enabled": true,

"watch-dir": "/home/downloads/watch/",

"watch-dir-enabled": true,

"download-limit": 100,

"download-limit-enabled": 0,

"encryption": 2,

"lazy-bitfield-enabled": true,

"lpd-enabled": false,

"max-peers-global": 200,

"message-level": 2,

"open-file-limit": 32,

"peer-limit-global": 240,

"peer-limit-per-torrent": 60,

"peer-port": 20628,

"peer-port-random-high": 20500,

"peer-port-random-low": 20599,

"peer-port-random-on-start": true,

"peer-socket-tos": 0,

"pex-enabled": true,

"port-forwarding-enabled": false,

"preallocation": 1,

"proxy": "",

"proxy-auth-enabled": false,

"proxy-auth-password": "",

"proxy-auth-username": "",

"proxy-enabled": false,

"proxy-port": 80,

"proxy-type": 0,

"ratio-limit": 0.2500,

"ratio-limit-enabled": true,

"rename-partial-files": true,

"rpc-authentication-required": true,

"rpc-bind-address": "0.0.0.0",

"rpc-enabled": true,

"rpc-username": "uzr",

"rpc-password": "pzw",

"rpc-port": 9091,

"rpc-whitelist": "127.0.0.1,*.*.*.*",

"rpc-whitelist-enabled": true,

"script-torrent-done-enabled": false,

"script-torrent-done-filename": "",

"speed-limit-down": 100,

"speed-limit-down-enabled": false,

"speed-limit-up": 1,

"speed-limit-up-enabled": true,

"start-added-torrents": true,

"trash-original-torrent-files": false,

"umask": 2,

"upload-limit": 100,

"upload-limit-enabled": 0,

"upload-slots-per-torrent": 1

}
EOM

# h5ai auth part
sed -i '2i\auth();' $H5AIINDEX
echo "function auth ()" >> $H5AIINDEX
echo "{" >> $H5AIINDEX
echo '$valid_passwords = array ("'${username}'" => "'${pass}'");' >> $H5AIINDEX
cat >> $H5AIINDEX <<- EOM
        \$valid_users = array_keys(\$valid_passwords);

        \$user = \$_SERVER['PHP_AUTH_USER'];
        \$pass = \$_SERVER['PHP_AUTH_PW'];

        \$validated = (in_array(\$user, \$valid_users)) && (\$pass == \$valid_passwords[\$user]);

        if (!\$validated) {
          header('WWW-Authenticate: Basic realm="My Realm"');
          header('HTTP/1.0 401 Unauthorized');
          die ("Not authorized");
        }
}
EOM

sed -i 's/uzr/'$username'/g' /etc/transmission-daemon/settings.json
sed -i 's/pzw/'$pass'/g' /etc/transmission-daemon/settings.json
echo "============================Restarting Services==========================="
service transmission-daemon reload
service php7.0-fpm restart
ulimit -n 8192
supervisorctl reload
# clear
echo "=============================================================================="
echo "                   Seedbox Installed successfully! "
echo "=============================================================================="
echo " Transmission WebUI URL:${blue} http://"$IP":9091${normal}"
echo "         h5ai WebUI URL:${blue} http://"$IP":9090${normal}"
echo "${green} ** Notice **: For initialization ,You need to"
echo " visit ${blue}http://"$IP":9090/_h5ai/public/index.php${normal}"
echo "${green} first and click login with empty password. Then you can enjoy h5ai${normal}"
echo " WebUI Username: $username"
echo " WebUI Password: $pass"
echo " Download Location: /home/downloads"
echo ""
echo "=============================================================================="
echo "                            Script by swain & WEN.pw                          "
echo "=============================================================================="