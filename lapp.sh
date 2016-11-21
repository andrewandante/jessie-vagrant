#! /usr/bin/env bash

# Install packages
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y apache2 postgresql-9.4 postgresql-client-9.4 php5 php5-pgsql php5-gd php5-mcrypt php5-curl vim curl git postfix
a2enmod rewrite
cp /usr/share/postfix/main.cf.debian /etc/postfix/main.cf
service postfix reload

sudo -u postgres psql -c "CREATE ROLE vagrant SUPERUSER LOGIN PASSWORD 'vagrant';"

# Set the webroot symlink
rm -rf /var/www/html
ln -s /vagrant/ /var/www/html
sed -i '/<Directory \/var\/www\/>/,/<\/Directory>/ { s/AllowOverride None/AllowOverride All/i }' /etc/apache2/apache2.conf

sed -i 's/APACHE_RUN_USER=www-data/APACHE_RUN_USER=vagrant/i' /etc/apache2/envvars
sed -i 's/APACHE_RUN_GROUP=www-data/APACHE_RUN_GROUP=vagrant/i' /etc/apache2/envvars

service apache2 restart

# Get sspak
curl -sS https://silverstripe.github.io/sspak/install | php -- /usr/local/bin

php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
php -r "if (hash_file('SHA384', 'composer-setup.php') === '$(curl -q https://composer.github.io/installer.sig)') { echo 'Installer verified' . PHP_EOL; } else { echo 'Installer corrupt' . PHP_EOL; unlink('composer-setup.php'); exit(1); }"
if [ $? != 0 ]; then
	echo "Bad composer installer";
	exit
fi
php composer-setup.php -- --install-dir=/usr/bin --filename=composer
php -r "unlink('composer-setup.php');"

composer config -g optimize-autoloader true

PATH=$PATH:~/.composer/vendor/bin
