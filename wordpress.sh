# PARAMETRES DATABASE
echo username?
read username
echo password?
read pswd
echo host name ?
read hostname
echo database?
read namedatabase
# UPDATE 
sudo apt update && sudo apt upgrade
# INSTALLATION APACHE
sudo apt install apache2
# INSTALLATION MARIADB-CLIENT
sudo apt install mariadb-client-core-10.1
# INSTALLATION PHP 
sudo apt install php php-mysql
# INSTALLATION WORDPRESS
cd /tmp 
sudo wget https://wordpress.org/latest.tar.gz
sudo tar -xvf latest.tar.gz
sudo cp -R wordpress /var/www/html/
sudo chown -R www-data:www-data /var/www/html/wordpress/
sudo chmod -R 755 /var/www/html/wordpress/
sudo mkdir /var/www/html/wordpress/wp-content/uploads
sudo chown -R www-data:www-data /var/www/html/wordpress/wp-content/uploads/
# CONFIGURATION MARIADB-CLIENT ET MARIADB-SERVEUR
mariadb --user=$username --password=$pswd --host=$hostname -e "create database $namedatabase;"

sudo cp /var/www/html/wordpress/wp-config-sample.php /var/www/html/wordpress/wp-config.php

sudo sed -i -e "s/database_name_here/$namedatabase/g" /var/www/html/wordpress/wp-config.php
sudo sed -i -e "s/username_here/$username/g" /var/www/html/wordpress/wp-config.php
sudo sed -i -e "s/password_here/$pswd/g" /var/www/html/wordpress/wp-config.php
sudo sed -i -e "s/localhost/$hostname/g" /var/www/html/wordpress/wp-config.php
