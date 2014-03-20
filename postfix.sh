#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

# Check if user is root
if [ $(id -u) != "0" ]; then
    echo "Error: You must be root to run this script, please use root to install lnmp"
    exit 1
fi

cur_dir=$(pwd)

echo "======postfix+dovecot+cyrus-sasl+postfixadmin one key install=========="
echo "================write by James Yang(james@shinesky.com)================"
echo "======================================================================="
postfixpwd="postfixpwd"
echo "Please input the postfix password of mysql:"
read -p "(Default password: postfixpwd):" postfixpwd
if [ "$postfixpwd" = "" ]; then
  postfixpwd="postfixpwd"
fi
echo "Please input your domain:"
read -p "(Default domain name: domain.com):" domainname
if [ "$domainname" = "" ]; then
  domainname="domain.com"
fi
echo "Please input the account name of postfixadmin administrator (should be your email address):"
read -p "(Default account name: admin@domain.com):" accountname
if [ "$accountname" = "" ]; then
  accountname="admin@domain.com"
fi
echo "================step 1: check install files==============="
if [ -s postfixadmin-2.3.2.tar.gz ]; then
  echo "postfixadmin [found]"
  else
  echo "postfixadmin not found, downloading now..."
  wget -c http://jaist.dl.sourceforge.net/project/postfixadmin/postfixadmin/postfixadmin-2.3.2/postfixadmin-2.3.2.tar.gz
fi

if [ -s postfix-2.7.2.tar.gz ]; then
  echo "postfix-2.7.2.tar.gz [found]"
  else
  echo "postfix not found, downloading now..."
  wget -c http://www.postfix.cn/source/official/postfix-2.7.2.tar.gz
fi

if [ -s dovecot-2.0.8.tar.gz ]; then
  echo "dovecot-2.0.8.tar.gz [found]"
  else
  echo "dovecot not found, downloading now..."
  wget -c http://dovecot.org/releases/2.0/dovecot-2.0.8.tar.gz
fi

if [ -s cyrus-sasl-2.1.23.tar.gz ]; then
  echo "cyrus-sasl-2.1.23.tar.gz [found]"
  else
  echo "cyrus-sasl not found, downloading now..."
  wget -c http://ftp.andrew.cmu.edu/pub/cyrus-mail/cyrus-sasl-2.1.23.tar.gz
fi

echo "===============step 2: stop sendmail========================"
read -p "press any key to continue....:" input_key
#service sendmail stop
#chkconfig --level 345 sendmail off
yum -y remove sendmail

cd $cur_dir
echo "===============step 3: intall cyrus-sasl==================="
read -p "press any key to continue....:" input_key
yum -y remove cyrus-sasl
tar xzvf cyrus-sasl-2.1.23.tar.gz
cd cyrus-sasl-2.1.23
./configure --enable-login --enable-sql --with-mysql=/usr/local/mysql/
make
make testsaslauthd
make install
ln -f -s /usr/local/lib/sasl2 /usr/lib64/sasl2
echo "/usr/sbin/saslauthd -a shadow">>/etc/rc.local

cd $cur_dir
echo "==============step 4: install postfixadmin======================"
read -p "press any key to continue....:" input_key
tar zxvf postfixadmin-2.3.2.tar.gz
mv -f postfixadmin-2.3.2 /home/wwwroot/postfixadmin
cd /home/wwwroot/postfixadmin
mv config.inc.php config.inc.php.bak
cp -f $cur_dir/conf/postfixadmin_config.inc.php config.inc.php
cp -f $cur_dir/conf/postfix.sql /home/wwwroot/
sed -i 's/postfixpwd/'$postfixpwd'/g' config.inc.php
sed -i 's/admin@domain.com/'$accountname'/g' config.inc.php
sed -i 's/domain.com/'$domainname'/g' config.inc.php
sed -i 's/admin@domain.com/'$accountname'/g' /home/wwwroot/postfix.sql
sed -i 's/postfixpwd/'$postfixpwd'/g' /home/wwwroot/postfix.sql
echo "login mysql root to import database:"
/usr/local/mysql/bin/mysql -uroot -p </home/wwwroot/postfix.sql
rm /home/wwwroot/postfix.sql -f
echo "fixing a bug in postfixadmin edit-mailbox.php:"
sed -i "s/formvars\['local_part'\]/formvars\['\$local_part'\]/g" /home/wwwroot/postfixadmin/edit-mailbox.php
echo "===============postfixadmin install completed=================="


cd $cur_dir
echo "===============step 5: install postfix======================"
read -p "press any key to continue(please always press enter key to continue till install complete)....:" input_key
yum -y remove postfix
groupdel postfix
userdel postfix
groupadd -g 1000 postfix
useradd -u 1000 -g postfix -s /sbin/nologin -d /dev/null postfix
groupadd -g 1001 postdrop
yum -y install db4-devel
tar zxvf postfix-2.7.2.tar.gz
cd postfix-2.7.2
make -f Makefile.init makefiles 'CCARGS=-DHAS_MYSQL -I/usr/include/mysql -DUSE_SASL_AUTH -DDEF_SERVER_SASL_TYPE=\"dovecot\"' 'AUXLIBS=-L/usr/lib/mysql -lmysqlclient -lz -lm'
make && make install
mv /etc/postfix/main.cf /etc/postfix/main.cf.bak
mv /etc/postfix/master.cf /etc/postfix/master.cf.bak
cp -f $cur_dir/conf/main.cf /etc/postfix/
cp -f $cur_dir/conf/master.cf /etc/postfix/
cp -f $cur_dir/conf/mysql-*.cf /etc/postfix/
sed -i "s/postfixpwd/$postfixpwd/g" `grep postfixpwd -rl /etc/postfix/*.cf`
echo "===============postfix install completed=================="

echo "===============step 6: install dovecot======================"
read -p "press any key to continue....:" input_key
yum -y remove dovecot
cd $cur_dir
groupdel dovecot
groupadd -g 1002 dovecot
tar zxvf dovecot-2.0.8.tar.gz
cd dovecot-2.0.8
./configure --prefix=/usr/local/dovecot --sysconfdir=/etc --with-mysql CPPFLAGS=-I/usr/include/mysql LDFLAGS=-L/usr/lib/mysql
make && make install
mv -f /etc/dovecot/dovecot.conf /etc/dovecot/dovecot.conf.bak
mv -f /etc/dovecot/dovecot-mysql.conf /etc/dovecot/dovecot-mysql.conf.bak
cp -f $cur_dir/conf/dovecot.conf /etc/dovecot/
cp -f $cur_dir/conf/dovecot-mysql.conf /etc/dovecot/
sed -i "s/postfixpwd/$postfixpwd/g" `grep postfixpwd -rl /etc/dovecot`
echo "===============dovecot install completed=================="

newaliases

mkdir -p /var/vmail
chown postfix:postfix /var/vmail -R

/usr/sbin/saslauthd -a shadow
/usr/local/dovecot/sbin/dovecot
#chown postfix:postfix /usr/local/dovecot/var/run/dovecot/auth-client -R
postfix start
echo "=============set 7: set postfix & dovecot startup================="
read -p "press any key to continue....:" input_key
echo "postfix start" >>/etc/rc.local
echo "/usr/local/dovecot/sbin/dovecot" >>/etc/rc.local

echo "Install postfix+dovecot+cyrus-sasl+postfixadmin completed! enjoy it."
echo "========================================================================="
echo "POSTFIX FOR REDHAT VPS  Written by James Yang (james@shinesky.com)"
echo "========================================================================="
echo "the mysql postfix user is account/password is postfix/"$postfixpwd
echo "default postfixadmin account/password:"$accountname"/admin"
echo "please browser http://www."$domainname"/postfixadmin/login.php to reset the password and setup your mailserver"


