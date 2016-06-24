#!/bin/bash


### copy this file into setup.sh, change directory to where it’s located
### and execute chmod +x setup.sh on the command prompt
### do not run as root, only use sudo

####################################
### WHAT THIS WILL INSTALL
### 1. Rvm
### 2. Ruby
### 3. Rails
### 4. MySQL, create users
### 5. Install nginx, configure PATH to look in
### 6. Download application from github to /home/$user/webapps
### 7. Run bundle install from application folder (this would include mysql2 adapter, capistrano, unicorn)
### 8. Run rake db:setup
### 9. Run capistrano to deploy/configure unicorn
###
###
### Linux server machine user: deploy, pass: deploypass
### MySQL root: root, pass: rootpass
### MySQL user: procmonapp pass: w2e3r4t5
### App name: processmonitor
####################################

echo '#################################################'
echo '### update and install dependencies'
echo '#################################################'
sudo apt-get update
sudo apt-get install -y curl git libmysqlclient-dev nodejs


echo '#################################################'
echo '### install rvm, ruby, rails and bundler'
echo '#################################################'
gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
\curl -sSL https://get.rvm.io | bash -s stable
source /etc/profile.d/rvm.sh
rvm requirements
rvm install 2.0.0
rvm use 2.0.0 --default
gem install rails --version 4.0.0 --no-ri --no-rdoc
gem install bundler


echo '#################################################'
echo '### install mysql-server'
echo '#################################################'

export DEBIAN_FRONTEND=noninteractive
sudo apt-get -q -y install mysql-server
mysqladmin -u root password rootpass 
# changes root password, or creates if none yet

mysql -uroot -prootpass -e "GRANT ALL PRIVILEGES ON *.* TO 'procmonapp'@'%' IDENTIFIED BY 'w2e3r4t5'"
mysql -uroot -prootpass -e "GRANT ALL PRIVILEGES ON *.* TO 'procmonapp'@'localhost' IDENTIFIED BY 'w2e3r4t5'"

sudo service mysql restart

echo '#################################################'
echo '### add environment variables to be used by app'
echo '#################################################'

echo 'export PROCMON_DBUSER=procmonapp' >> ~/.bashrc
echo 'export PROCMON_DBPASS=w2e3r4t5' >> ~/.bashrc
source ~/.bashrc



echo '#################################################'
echo '### download app from git and bundle gems'
echo '#################################################'

git clone https://github.com/atuaradil/processmonitor.git /var/www/processmonitor
cd /var/www/processmonitor
mkdir -p /var/www/processmonitor/shared/pids /var/www/processmonitor/shared/sockets /var/www/processmonitor/shared/log
/var/www/processmonitor/bundle install

echo '#################################################'
echo '### create unicorn service config for the app'
echo '#################################################'
sudo cp /var/www/processmonitorscripts/unicorn_processmonitor.txt /etc/init.d/unicorn_processmonitor

sudo chmod 755 /etc/init.d/unicorn_processmonitor
sudo update-rc.d unicorn_processmonitor defaults

sudo service unicorn_processmonitor start

echo '#################################################'
echo '### install nginx and configure for the app'
echo '#################################################'
sudo apt-get -y install nginx
# ip addr show eth0 | grep inet | awk '{ print $2; }' | sed 's/\/.*$//'

sudo cp /var/www/processmonitorscripts/nginx_processmonitor.txt /etc/nginx/sites-available/processmonitor 

sudo ln -s /etc/nginx/sites-available/processmonitor /etc/nginx/sites-enabled/processmonitor



echo '#################################################'
echo '### install nginx and configure for the app'
echo '#################################################'
/var/www/processmonitor/rake db:create RAILS_ENV=production 
/var/www/processmonitor/rake db:migrate RAILS_ENV=production 
/var/www/processmonitor/rake db:seed RAILS_ENV=production 
/var/www/processmonitor/rake assets:precompile RAILS_ENV=production 



sudo service nginx restart