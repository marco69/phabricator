#!/bin/bash
APPENV=local
DBHOST=localhost
DBNAME=phabricator_db
DBUSER=phabricator
DB_ROOT_PASSWD=peloia10
DB_PASSWD=phabricator

confirm () {
    # call with a prompt string or use a default
    read -r -p "${1:-PLease confirm your choise? [y/N]} " response
    case $response in
        [yY][eE][sS]|[yY]) 
            true
            ;;
        *)
            false
            ;;
    esac
}

echo -e "\n--- Start installation of the packages needed... ---\n"

echo -e "\n--- Updating packages list of the ubuntu server---\n"
apt-get -qq update > /dev/null 2>&1

echo -e "\n--- Install base packages ---\n"
apt-get -y install vim curl build-essential python-software-properties > /dev/null 2>&1
echo -e "\n--- Install git ---\n"
apt-get -y install git > /dev/null 2>&1

echo -e "\n--- Install MySQL specific packages and settings ---\n"
echo "mysql-server mysql-server/root_password password $DB_ROOT_PASSWD" | debconf-set-selections
echo "mysql-server mysql-server/root_password_again password $DB_ROOT_PASSWD" | debconf-set-selections
apt-get -y install mysql-server-5.5 mysql-client > /dev/null 2>&1

echo -e "\n--- Setting up our MySQL user and db ---\n"
if [ ! -f /var/log/dbinstalled ];
then
    echo "CREATE USER '$DBUSER'@'localhost' IDENTIFIED BY '$DB_PASSWD'" | mysql -uroot -p$DB_ROOT_PASSWD
    echo "CREATE DATABASE $DBNAME" | mysql -uroot -p$DB_ROOT_PASSWD
    echo "GRANT ALL ON $DBNAME.* TO '$DBUSER'@'localhost'" | mysql -uroot -p$DB_ROOT_PASSWD
    echo "flush privileges" | mysql -uroot -p$DB_ROOT_PASSWD
    touch /var/log/dbinstalled
fi

echo -e "\n--- Installing apache and PHP-specific packages.... ---\n"
apt-get -y install php5 apache2 openssl libapache2-mod-php5 php5-curl php5-gd php5-mcrypt php5-mysql php-apc > /dev/null 2>&1

echo -e "\n--- changing user to Apache ---\n"
APACHEUSR=`grep -c 'APACHE_RUN_USER=www-data' /etc/apache2/envvars`
APACHEGRP=`grep -c 'APACHE_RUN_GROUP=www-data' /etc/apache2/envvars`
if [ APACHEUSR ]; then
    sed -i 's/APACHE_RUN_USER=www-data/APACHE_RUN_USER=vagrant/' /etc/apache2/envvars
fi
if [ APACHEGRP ]; then
    sed -i 's/APACHE_RUN_GROUP=www-data/APACHE_RUN_GROUP=vagrant/' /etc/apache2/envvars
fi
sudo chown -R vagrant:www-data /var/lock/apache2
echo -e "\n--- Enabling mod-rewrite.... ---\n"
a2enmod rewrite > /dev/null 2>&1

echo -e "\n--- Allowing Apache override to all.... ---\n"
sed -i "s/AllowOverride None/AllowOverride All/g" /etc/apache2/apache2.conf

echo -e "\n--- Setting document root to public directory ---\n"
rm -rf /var/www
ln -fs /vagrant/ /var/www

echo -e "\n--- Turn on PHP errors ...... ---\n"
sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php5/apache2/php.ini
sed -i "s/display_errors = .*/display_errors = On/" /etc/php5/apache2/php.ini





/usr/sbin/a2ensite default
echo -e "\n--- Restarting Apache ---\n"
service apache2 restart > /dev/null 2>&1

ROOT='/var/www'
echo "Phabricator will be installed to: ${ROOT}.";
confirm
cd ${ROOT}
HAVEPCNTL=`php -r "echo extension_loaded('pcntl');"`
if [ $HAVEPCNTL != "1" ]
then
  echo "Installing pcntl...";
  echo
  apt-get source php5
  PHP5=`ls -1F | grep '^php5-.*/$'`
  (cd $PHP5/ext/pcntl && phpize && ./configure && make && sudo make install)
else
  echo "pcntl already installed";
fi

if [ ! -e libphutil ]
then
  git clone https://github.com/phacility/libphutil.git
else
  (cd libphutil && git pull --rebase)
fi

if [ ! -e arcanist ]
then
  git clone https://github.com/phacility/arcanist.git
else
  (cd arcanist && git pull --rebase)
fi

if [ ! -e phabricator ]
then
  git clone https://github.com/phacility/phabricator.git
else
  (cd phabricator && git pull --rebase)
fi

echo
echo
echo "Install probably worked mostly correctly. Continue with the 'Configuration Guide':";
echo
echo "https://secure.phabricator.com/book/phabricator/article/configuration_guide/";
echo
echo "You can delete any php5-* stuff that's left over in this directory if you want.";

