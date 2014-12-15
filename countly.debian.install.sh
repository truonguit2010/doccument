#!/bin/bash
# debian count.ly install script
# by: Truong PS
# Tested on wheezy (v7.7)

set -e

if [[ $EUID -ne 0 ]]; then
echo "Please execute Countly installation script with a superuser..." 1>&2
exit 1
fi

echo "
______                  __  __
/ ____/___  __  ______  / /_/ /_  __
/ /   / __ \/ / / / __ \/ __/ / / / /
/ /___/ /_/ / /_/ / / / / /_/ / /_/ /
\____/\____/\__,_/_/ /_/\__/_/\__, /
http://count.ly/____/

"

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

#update package index
apt-get update

apt-get -y install python python-software-properties

if !(command -v apt-add-repository >/dev/null) then
apt-get -y install software-properties-common
fi

apt-get -y install build-essential python-dev || (echo "Failed to install build-essential." ; exit)

# install cElementTree (faster XML parser)
wget -N http://effbot.org/media/downloads/cElementTree-1.0.5-20051216.tar.gz
tar xzvf cElementTree* && cd cElementTree*
python setup.py install
cd ..
pwd

# build node.js dpkg, install
#apt-get install g++ make checkinstall
#mkdir nodejs-src && cd $_
#pwd
#wget -N http://nodejs.org/dist/node-latest.tar.gz
#tar xzvf node-latest.tar.gz && cd node-v*
#pwd
#./configure
#pwd
# remove the "v" in front of the version number in
# the pkg build dialog, or the pkg won't build/validate
#checkinstall
#dpkg -i node_*
apt-get install curl
curl -sL https://deb.nodesource.com/setup | bash -
apt-get install -y nodejs

#add mongodb repo
apt-key adv --keyserver keyserver.ubuntu.com --recv 7F0CEB10
echo 'deb http://downloads-distro.mongodb.org/repo/debian-sysvinit dist 10gen' | tee /etc/apt/sources.list.d/10gen.list

#update once more after adding new repos
apt-get update

#install nginx
apt-get -y install nginx || (echo "Failed to install nginx." ; exit)

#install node.js
#apt-get -y --force-yes install nodejs || (echo "Failed to install nodejs." ; exit)

#install mongodb
apt-get -y --force-yes install mongodb-10gen || (echo "Failed to install mongodb." ; exit)

#install supervisor
apt-get -y install supervisor || (echo "Failed to install supervisor." ; exit)

#install imagemagick
apt-get -y install imagemagick

#install sendmail
apt-get -y install sendmail-bin sendmail

#install time module for node
( cd $DIR/../api ; npm install time )

#configure and start nginx
cp /etc/nginx/sites-enabled/default $DIR/config/nginx.default.backup
cp $DIR/config/nginx.server.conf /etc/nginx/sites-enabled/default
/etc/init.d/nginx restart

if [ ! -f $DIR/../frontend/express/public/javascripts/countly/countly.config.js ]; then
cp $DIR/../frontend/express/public/javascripts/countly/countly.config.sample.js $DIR/../frontend/express/public/javascripts/countly/countly.config.js
fi

#kill existing supervisor process
pkill -SIGTERM supervisord

#create supervisor upstart script and start supervisord
(cat $DIR/config/countly-supervisor.conf ; echo "exec /usr/bin/supervisord --nodaemon --configuration $DIR/config/supervisord.conf") > /etc/init/countly-supervisor.conf

#create api configuration file from sample
if [ ! -f $DIR/../api/config.js ]; then
cp $DIR/../api/config.sample.js $DIR/../api/config.js
fi

#create app configuration file from sample
if [ ! -f $DIR/../frontend/express/config.js ]; then
cp $DIR/../frontend/express/config.sample.js $DIR/../frontend/express/config.js
fi

#finally start countly api and dashboard
#start countly-supervisor
#echo 'You can now start using count.ly on http://localhost'

sed -i 's/NAME=supervisord/NAME=countly-supervisord/g' /etc/init.d/supervisor

sed -i 's/DAEMON_OPTS="-c /etc/supervisor/supervisord.conf $DAEMON_OPTS"/DAEMON_OPTS="-c /etc/init/countly-supervisor.conf $DAEMON_OPTS"/g' /etc/init.d/supervisor

cp /etc/init.d/supervisor /etc/init.d/countly-supervisor
service countly-supervisor start



