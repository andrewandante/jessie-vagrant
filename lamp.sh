#!/bin/bash

set -ex

export DEBIAN_FRONTEND=noninteractive

apt-get -q update
apt-get install -y apt-transport-https lsb-release software-properties-common

# gives "wheezy" or "jessie" or whatever this debian release's codename is
DEBIAN_CODENAME="$(lsb_release -cs)";

apt-get autoclean

# add deb.sury for PHP backports
apt-get -y install wget apt-transport-https lsb-release ca-certificates
wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
echo "deb https://packages.sury.org/php/ ${DEBIAN_CODENAME} main" >> /etc/apt/sources.list.d/php.list
echo "deb-src https://packages.sury.org/php/ ${DEBIAN_CODENAME} main" >> /etc/apt/sources.list.d/php.list

# update again, as we installed the new backports source
apt-get -q update
# install required packages
apt-get install -y unattended-upgrades build-essential less vim curl sysstat htop ntp \
	lsof telnet wget git \
	ssl-cert ca-certificates \
	python python-pip python-yaml \
	ruby ruby-dev \
	swaks libsasl2-modules postfix mailutils \
	mysql-server libgeo-ipfree-perl \
	realpath logtail \
	nfs-common

php_versions=("7.1")
php_extensions=(
	"apcu"
	"bcmath"
	"bz2"
	"common"
	"cli"
	"curl"
	"dba"
	"dev"
	"gd"
	"imagick"
	"intl"
	"ldap"
	"mbstring"
	"mcrypt"
	"mysql"
	"opcache"
	"soap"
	"sqlite3"
	"tidy"
	"xmlrpc"
	"xsl"
	"zip"
)

for version in ${php_versions[@]}; do
	apt-get -y install "php$version" "libapache2-mod-php$version" "${php_extensions[@]/#/php$version-}"
done

a2enmod rewrite
cp /usr/share/postfix/main.cf.debian /etc/postfix/main.cf
service postfix reload
# Set the webroot symlink
rm -rf /var/www/html
ln -s /vagrant/ /var/www/html
sed -i '/<Directory \/var\/www\/>/,/<\/Directory>/ { s/AllowOverride None/AllowOverride All/i }' /etc/apache2/apache2.conf

sed -i 's/APACHE_RUN_USER=www-data/APACHE_RUN_USER=vagrant/i' /etc/apache2/envvars
sed -i 's/APACHE_RUN_GROUP=www-data/APACHE_RUN_GROUP=vagrant/i' /etc/apache2/envvars

service apache2 restart

# Get sspak
if [ ! -e /usr/local/bin/sspak ]; then
	curl -sS https://silverstripe.github.io/sspak/install | php -- /usr/local/bin
fi

# Get composer
if [ ! -e /usr/bin/composer ]; then
	php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
	php -r "if (hash_file('SHA384', 'composer-setup.php') === '$(curl -q https://composer.github.io/installer.sig)') { echo 'Installer verified' . PHP_EOL; } else { echo 'Installer corrupt' . PHP_EOL; unlink('composer-setup.php'); exit(1); }"
	if [ $? != 0 ]; then
		echo "Bad composer installer";
		exit
	fi
	php composer-setup.php -- --install-dir=/usr/bin --filename=composer
	php -r "unlink('composer-setup.php');"

	composer config -g optimize-autoloader true
fi

PATH=$PATH:~/.composer/vendor/bin

# Set up Xdebug
XDEBUG_INSTALLED=`pecl list | grep xdebug | wc -l`

if [ $XDEBUG_INSTALLED -lt 1 ]; then
    pecl install Xdebug
fi

if [ ! -f /etc/php/7.1/apache2/conf.d/20-xdebug.ini ]; then
    echo "[xdebug]
    zend_extension=\"/usr/lib/php/7.1/20131226/xdebug.so\"
    xdebug.profiler_enable = 1
    xdebug.profiler_enable_trigger = 1
    xdebug.profiler_append = 1
    xdebug.profiler_output_dir=\"/tmp/xdebug_profiler/\"
    xdebug.profiler_output_name=\"%H_%R_%p_cachegrind.out\"
    xdebug.remote_connect_back = 1
    xdebug.remote_enable = 1
    xdebug.remote_port = 2200" > /etc/php/7.1/apache2/conf.d/20-xdebug.ini
fi