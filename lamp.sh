#/usr/bin/env bash

# Install packages
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y apache2 mysql-server php5 php5-gd php5-mcrypt php5-mysql php5-ldap php5-curl vim curl git postfix php5-dev
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
pecl install Xdebug

if [ ! -f /etc/php5/apache2/conf.d/20-xdebug.ini ]
then
    echo "[xdebug]
    zend_extension=\"/usr/lib/php5/20131226/xdebug.so\"
    xdebug.profiler_enable = 1
    xdebug.profiler_enable_trigger = 1
    xdebug.profiler_append = 1
    xdebug.profiler_output_dir=\"/tmp/xdebug_profiler/\"
    xdebug.profiler_output_name=\"%H_%R_%p_cachegrind.out\"
    xdebug.remote_connect_back = 1
    xdebug.remote_enable = 1
    xdebug.remote_port = 2200" > /etc/php5/apache2/conf.d/20-xdebug.ini
fi