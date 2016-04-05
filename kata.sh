#!/bin/bash -e

# Michele Welponer, wp install automation bash script 
# Copyright (C) 2016  Michele Welponer

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

servername=$(hostname)
wpuser=$(whoami)
mysqlRootPass="qwerty"
clear


# ============== FUNCTIONS ===============
# COLORS
RS="\033[0m"    # reset
FRED="\033[31m" # foreground red
FGRN="\033[32m" # foreground green
LGRN="\033[38;5;82m" # foreground light green
FYEL="\033[33m"
LMAG="\033[95m" # light magenta

function program_is_installed {
  # set to 1 initially
  local return_=1
  # set to 0 if not found
  # STDIN, STDOUT, and STDERR are numbered as 0, 1, 2
  # so
  # 2>&1 redirects STDERR in STDOUT
  type $1 >/dev/null 2>&1 || { local return_=0; }
  # return value
  echo "$return_"
}

function echo_error {
  printf "$FRED[ERROR] ${1}"
  printf "$RS\n"
  exit 1
}
function echo_success {
  printf "$LGRN${1}"
  printf "$RS\n"
}
function echo_warning {
  printf "$FYEL[WARNING] ${1}"
  printf "$RS\n"
}
function echo_info {
  printf "$LMAG[INFO] ${1}"
  printf "$RS\n"
}
function echo_if {
  if [ $1 == 1 ]; then
    echo_success "✔ $2"
  else
    printf "$FRED ✘ $2"
    printf "$RS\n"
  fi
}


# ============== DEPENDENCIES ===============
echo_info "---------- Check Dependencies ----------"
echo "* php5 $(echo_if $(program_is_installed php5))"
echo "* apache2 $(echo_if $(program_is_installed apache2))"
echo "* mysql $(echo_if $(program_is_installed mysql))"
echo "* wp $(echo_if $(program_is_installed wp))"

if [ $(program_is_installed php5) == 0 ] ;  then
  echo_info  "Installing PHP5...."
  sudo apt-get install php5 libapache2-mod-php5 php5-mysql php5-mcrypt php5-gd php5-xmlrpc php5-curl
fi

if [ $(program_is_installed apache2) == 0 ] ;  then
  echo_info  "Installing Apache...."
  sudo apt-get install apache2
fi

if [ $(program_is_installed mysql) == 0 ] ;  then
  echo_info "Installing Mysql server...."
  echo "mysql-server-5.6 mysql-server/root_password password $mysqlRootPass" | debconf-set-selections
  echo "mysql-server-5.6 mysql-server/root_password_again password $mysqlRootPass" | debconf-set-selections
  sudo apt-get -y install mysql-server-5.6
else
  read -s -p "Mysql root Password: " mysqlRootPass
fi

#if [ ! -f /usr/local/bin/wp ]; then
if [ $(program_is_installed wp) == 0 ] ;  then
  echo_info "Installing WP-CLI...."
  curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
  #php wp-cli.phar --info
  chmod +x wp-cli.phar
  sudo mv wp-cli.phar /usr/local/bin/wp
fi


# ============== INTERACTIVE SET-UP ===============
echo ""
echo ""
echo_info "---------- Set-up ----------"
# server name
SiteURL="www.$servername"
echo "SiteURL: $SiteURL"
echo "Would you like to change it? (y/n)"
read -e chg
if [ "$chg" == y ] ; then
  echo "Set SiteURL:"
  read -e SiteURL
fi

# database name
echo ""
echo "Set DB name: "
read -e dbname

# website title
echo ""
echo "Set site title: "
read -e sitename

docRoot="/var/www/$sitename"

#if [ ! -d $docRoot ] ; then
#  sudo mkdir $docRoot
#  sudo chown $wpuser:$wpuser $docRoot
#  cp mysql_secure_installation.sql $docRoot
#  cd $docRoot
#else
#  echo "Folder $docRoot already present"
#  echo "Ok to overwrite it? (y/n)"
#  read -e ok
#  if [ "$ok" == n ] ; then
#    echo "..Exit!"
#    exit 1
#  else
#    sudo rm -rf $docRoot
#    sudo mkdir $docRoot
#    sudo chown $wpuser:$wpuser $docRoot
#    cp mysql_secure_installation.sql $docRoot
#    cd $docRoot
#  fi
#fi
if [ -d $docRoot ] ; then
  echo_warning "Folder $docRoot already present.\nOk to overwrite it? (y/n)"
  read -e ok
  if [ "$ok" == n ] ; then
    echo "..Exit!"
    exit 1
  fi
fi
sudo rm -rf $docRoot
sudo mkdir $docRoot
sudo chown $wpuser:$wpuser $docRoot
cp mysql_secure_installation.sql $docRoot
cd $docRoot


echo "user: $wpuser" > install.log
sudo chmod 600 install.log

# admin email
echo ""
echo "Set Admin email: "
read -e aemail

echo ""
echo "Ready to install? (y/n)"
read -e go

if [ "$go" == n ] ; then
  echo "..Exit!"
  exit 1
else
  
  
# ============== WP INSTALLATION =============== 
echo ""
echo_info "---------- Wordpress Installation ----------"
# download WP core files
wp core download

# create the wp-config file
wp core config --dbname=$dbname --dbuser=root --dbpass=$mysqlRootPass --extra-php <<PHP
define( 'WP_DEBUG', true );
define( 'DISALLOW_FILE_EDIT', true ); 
PHP

# parse the current directory name
#currdir=${PWD##*/}
#echo "currentdirectory: " $currentdirectory

# generate random 12 character password
password=$(LC_CTYPE=C tr -dc A-Za-z0-9_\!\@\#\$\%\^\&\*\(\)-+= < /dev/urandom | head -c 12)

echo "pass: "$password >> install.log
# copy password to clipboard
#echo $password | pbcopy

# create database, and install WordPress
wp db create
wp core install --url="http://$SiteURL" --title="$sitename" --admin_user="$wpuser" --admin_password="$password" --admin_email="$aemail"


echo_info "---------- Better WP Security plugin Installation ----------"
echo "Features:"
echo "- Additional “security through obscurity” options"
echo "- Change the current WordPress database prefix"
echo "- Rename the default “admin” username"
echo "- Change the ID for the user with ID 1"
echo "- Removes login error messages (so bad login attempts don’t get a hint"
echo "- whether it was the username or the password that was incorrect)"
echo "- Logs 404 errors, bad login attempts, and changes to files"
echo "Needs to be configured."
echo ""
wp plugin install better-wp-security
echo_success "Plugin installed."

echo_info "---------- Super cache plugin Installation ----------"
echo "This plugin generates static html files from your dynamic WordPress blog."
echo "After a html file is generated your webserver will serve that file instead" 
echo "of processing the comparatively heavier and more expensive WordPress PHP scripts."
echo "Needs to be configured."
echo ""
wp plugin install wp-super-cache
echo_success "Plugin installed."

echo_info "---------- Antispam Bee plugin Installation ----------"
echo "Antispam Bee blocks spam comments and trackbacks effectively and without captchas." 
echo "It is free of charge, ad-free and compliant with European data privacy standards."
wp plugin install antispam-bee --activate
echo_success "Plugin installed."

echo "================================================================="
echo_success "Wordpress Installation complete."
echo "Username and password are listed below. Also saved into file install.log"
echo ""
echo "Username: $wpuser"
echo "Password: $password"
echo ""
echo "================================================================="


# ============== SECURE THE MySQL ===============
echo ""
echo_info "---------- Securing MySQL ----------"

echo "Would you like to change Mysql root password? (y/n)"
read -e chg
if [ "$chg" == y ] ; then
  read -s -p "Set Mysql root Password: " newMysqlRootPass
  mysql -u root -p$mysqlRootPass -Bse 'UPDATE user SET password=PASSWORD("$newMysqlRootPass") WHERE User="root"'
  mysqlRootPass=$newMysqlRootPass
  echo "Mysql root pass: "$mysqlRootPass >> install.log
  echo_success "Password changed and saved into file install.log"
fi

mysql -sfu root -p$mysqlRootPass < "mysql_secure_installation.sql"
echo_success "MySQL secured."
#TODO: check if mysql bind address is enabled (localhost/server_ip/127.0.0.1)
echo_warning "Check in /etc/mysql/my.cnf if bind-address is enabled and tune it /n as needed."

# ============== SECURE FILE PERMISSIONS ===============
echo ""
echo_info "---------- Securing file Permissions ----------"
WP_OWNER=$wpuser # &lt;-- wordpress owner
WP_GROUP="www-data" # &lt;-- wordpress group
WP_ROOT=$docRoot # &lt;-- wordpress root directory
WS_GROUP="www-data" # &lt;-- webserver group
 
# reset to safe defaults
find ${WP_ROOT} -exec sudo chown ${WP_OWNER}:${WP_GROUP} {} \;
find ${WP_ROOT} -type d -exec sudo chmod 755 {} \;
find ${WP_ROOT} -type f -exec sudo chmod 644 {} \;
 
# allow wordpress to manage wp-config.php (but prevent world access)
sudo chgrp ${WS_GROUP} ${WP_ROOT}/wp-config.php
sudo chmod 660 ${WP_ROOT}/wp-config.php
 
# allow wordpress to manage .htaccess
sudo touch ${WP_ROOT}/.htaccess
sudo chgrp ${WS_GROUP} ${WP_ROOT}/.htaccess
sudo chmod 664 ${WP_ROOT}/.htaccess
 
# allow wordpress to manage wp-content
find ${WP_ROOT}/wp-content -exec sudo chgrp ${WS_GROUP} {} \;
find ${WP_ROOT}/wp-content -type d -exec sudo chmod 775 {} \;
find ${WP_ROOT}/wp-content -type f -exec sudo chmod 664 {} \;

# reset install.log 
sudo chmod 600 install.log
echo_success "File Permissions secured."


# ============== APACHE CONFIGURATION ===============
echo ""
echo_info "---------- Setting-up Apache Virtualhost ----------"
vhostpath="/etc/apache2/sites-available/$sitename.conf"

if [ -f $vhostpath ] ; then
  echo_warning "Virtualhost $vhostpath already present.\nOk to overwrite it? (y/n)"
  read -e ok
  if [ "$ok" == n ] ; then
    echo "..Exit!"
    exit 1
  fi
  sudo rm $vhostpath 
fi

sudo touch $vhostpath
sudo chown $wpuser $vhostpath
sudo echo "<VirtualHost *:80>" >> $vhostpath
sudo echo "  ServerName $SiteURL" >> $vhostpath
sudo echo "  ServerAdmin $aemail" >> $vhostpath
sudo echo "  DocumentRoot $docRoot" >> $vhostpath
sudo echo "  ErrorLog \${APACHE_LOG_DIR}/$sitename.error.log" >> $vhostpath
sudo echo "  CustomLog \${APACHE_LOG_DIR}/$sitename.access.log combined" >> $vhostpath
sudo echo "</VirtualHost>" >> $vhostpath
sudo chown root $vhostpath

#sudo a2dissite 000-default.conf
sudo a2ensite $sitename
sudo service apache2 reload
echo_success "Apache virtualhost created."

fi






exit 1







###BACKUP CODE###
#how to manually update the remote wp

#backup
mysqldump -h localhost -u root -p $dbname --ignore-table=$dbname.wp-users > $dbname.`date +%Y%m%d`.sql
#restore (remote)
mysql -u root -p $dbname < $dbname.20160404.sql

#update db siteurl (remote)
#..in /etc/hosts put 127.0.0.1 www.example.net
mysql -u username -puserpass dbname -e "UPDATE wp-options SET siteurl = 'http://$servername' WHERE option_id=1";

#backup
tar -czvf folder.`date +%Y%m%d`.tgz --exclude='wp-config.php' folder/
#restore (remote)
tar -xzvf file.tgz

