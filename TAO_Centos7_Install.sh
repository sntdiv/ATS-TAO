#!/bin/bash
# SCRIPT TO SETUP FRESH INSTALL FOR TAO 3.2 W/ PHP 7.3

ROOT_UID=0 #Root has $UID 0
SUCCESS=0
E_USEREXISTS=70
E_NOTROOT=65 #Not root

#Run as root, and this checks to see if the creater is in root. If not, will not run
if [ "$UID" -ne "$ROOT_UID" ]; then
echo "Sorry must be in root to run this script"
exit $E_NOTROOT
fi
echo "*********************************************************************"
echo "*********************************************************************"
echo "UPDATING SYSTEM WITH YUM"
echo "*********************************************************************"

timedatectl set-timezone America/New_York

yum -y install epel-release nano
yum -y update

echo "*********************************************************************"
echo "*********************************************************************"
echo "YUM UPDATE COMPLETE"
echo "*********************************************************************"
echo "*********************************************************************"
echo "*********************************************************************"
echo "*************************Setup a non-root user.**********************"
echo "*********************************************************************"
echo "What is your new username: "
read user
echo "Type in the password: "
read passwd
useradd $user -d /home/$user -m;
echo $passwd | passwd $user --stdin;
usermod -aG wheel $user
echo "*********************************************************************"
echo "*********************************************************************"
echo "*********************************************************************"
echo "The user $user has been setup!"
echo "*********************************************************************"
echo "*********************************************************************"
echo "INSTALL YUM CRON to run security updates automatically"
yum -y install yum-cron
systemctl start yum-cron
systemctl enable yum-cron

echo "*********************************************************************"
echo "UPDATING YUM-CRON.CONF FILE"
sed -i "/update_cmd = default/c\update_cmd = security" /etc/yum/yum-cron.conf
sed -i "/apply_updates = no/c\apply_updates = yes" /etc/yum/yum-cron.conf
sed -i "/emit_via = stdio/c\emit_via = email" /etc/yum/yum-cron.conf
echo "*********************************************************************"
echo "*********************************************************************"
systemctl restart yum-cron
echo "CRON FILE UPDATED"
echo "*********************************************************************"
echo "*********************************************************************"

echo "SETUP YOUR HOSTNAME"
echo "What is your system's hostname? e.g. gbviper.gbarcc.com "
read hostnm
hostnamectl set-hostname "$hostnm"

echo "EDIT HOSTS FILE"
sed -i "/127/{s/:/ /g;s/.*=//;s/$/ $hostnm/p}" /etc/hosts

echo "*********************************************************************"
echo "*********************************************************************"
echo "/etc/hosts file updated"
echo "*********************************************************************"
echo "*********************************************************************"

echo 'export HISTSIZE=' >> ~/.bashrc
echo 'export HISTSIZE=' >> /home/$usernm/.bashrc
echo 'export HISTFILESIZE=' >> ~/.bashrc
echo 'export HISTFILESIZE=' >> /home/$usernm/.bashrc
echo 'export HISTCONTROL=ignoredups:erasedups' >> ~/.bashrc
echo 'export HISTCONTROL=ignoredups:erasedups' >> /home/$usernm/.bashrc
echo 'shopt -s histappend' >> ~/.bashrc
echo 'shopt -s histappend' >> /home/$usernm/.bashrc
echo "export PROMPT_COMMAND=\"\${PROMPT_COMMAND:+\$PROMPT_COMMAND$'\n'}history -a; history -c; history -r\"" >> ~/.bashrc
echo "export PROMPT_COMMAND=\"\${PROMPT_COMMAND:+\$PROMPT_COMMAND$'\n'}history -a; history -c; history -r\"" >> /home/$usernm/.bashrc

echo "*********************************************************************"
echo "*********************************************************************"
echo ".bashrc history updated"
echo "*********************************************************************"
echo "*********************************************************************"

cp /etc/securetty /etc/securetty.bak
echo "tty1" > /etc/securetty
chmod 700 /root
authconfig --passalgo=sha512 --update

echo "Setup Firewalld"
systemctl enable firewalld
systemctl start firewalld
#add port 54111 for firewall
echo "firewall update"
firewall-cmd --add-service=http --permanent
firewall-cmd --add-service=https --permanent
firewall-cmd --add-port 54111/tcp --permanent
firewall-cmd --permanent --direct --add-rule ipv4 filter INPUT_direct 0 -p tcp --dport 54111 -m state --state NEW -m recent --set
firewall-cmd --permanent --direct --add-rule ipv4 filter INPUT_direct 1 -p tcp --dport 54111 -m state --state NEW -m recent --update --seconds 30 --hitcount 4 -j REJECT --reject-with tcp-reset
echo "firewall update"
firewall-cmd --reload
echo "Firewalld configuration complete... "
sed -i "/PermitRootLogin yes/c\PermitRootLogin no" /etc/ssh/sshd_config
echo "Protocol 2" >> /etc/ssh/sshd_config
echo "Port 54111" >> /etc/ssh/sshd_config
systemctl restart sshd
echo "SSHD Configuration Complete..."
echo "########################################################################"
echo "########################################################################"
echo "########################################################################"
echo "######################## CONFIG COMPLETE ################################"
echo "####################### SSHD  on port 54111   #################################"
echo "########################################################################"
echo "########################################################################"
echo "########################################################################"

echo 0 > /selinux/enforce
sed -i s/^SELINUX=.*$/SELINUX=disabled/ /etc/selinux/config
echo "selinux disabled"
echo "\n"

yum -y install git
yum -y install yum-utils
yum -y install php-cli php-zip wget unzip
#3b: Install Nodejs & NPM
curl -sL https://rpm.nodesource.com/setup_12.x | sudo -E bash -
yum install -y nodejs

echo "Setting up Apache2"
yum -y install httpd
systemctl enable httpd
systemctl start httpd

echo "Setting up MariaDB"
echo
yum -y install mariadb-server
systemctl start mariadb
systemctl enable mariadb
## set security options
mysql_secure_installation  ###Set root password and other security options
## test installation
mysqladmin -u root -p version
read -p "Press key to continue.. " -n1 -s

echo "Setting up REMI PHP"
rpm -Uvh http://rpms.famillecollet.com/enterprise/remi-release-7.rpm
yum update
yum-config-manager --enable remi-php71  #sets install to php7.3 ***7.2 fails***
yum -y install php
yum -y install php-mbstring
yum -y install php-gd
yum -y install php-pdo.x86_64
yum -y install php-mysqlnd.x86_64
yum -y install php-xml.x86_64
yum -y install php-opcache.x86_64
yum -y install php-pecl-zip.x86_64
systemctl restart httpd.service

read -p "Press key to continue.. " -n1 -s

echo "Installing TAO"
wget http://releases.taotesting.com/TAO_3.2.0-RC2_build.zip
unzip TAO_3.2.0-RC2_build.zip -d /var/www/html/
mv /var/www/html/TAO_3.2.0-RC2_build /var/www/html/tao/
chown -R apache /var/www/html/tao/

echo "pulling needed files from git"
cd ~
mv /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd.conf.orig.bak 
git clone https://github.com/mblue01/ATSTao3.2.git
cp ./ATSTao3.2/tao.conf /etc/httpd/conf.d/
cp ./ATSTao3.2/httpd.conf /etc/httpd/conf/
systemctl restart httpd

cd ~
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
HASH="$(wget -q -O - https://composer.github.io/installer.sig)"
php -r "if (hash_file('SHA384', 'composer-setup.php') === '$HASH') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
sudo php composer-setup.php --install-dir=/usr/local/bin --filename=composer

cd /var/www/html/tao/
/usr/local/bin/composer install

echo "Installing MathJax"
cp ~/ATSTao3.2/mathjax.sh /var/www/html/tao/
cd /var/www/html/tao/
chmod +x /var/www/html/tao/mathjax.sh
source /var/www/html/tao/mathjax.sh
echo ""
echo ""
echo "Install Complete. Goto http://gbtao.gbarcc.com/tao/install"
