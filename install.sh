#!/usr/bin/env bash
#  Install server-configs-nginx, 7G Firewall and nginx-ultimate-bad-bot-blocker

#  Uses https://gist.github.com/tricarte/8c4595ef50649a91e2ca6462c27f2d42
#  as nginx virtual host template.

# wget
# https://gist.githubusercontent.com/tricarte/8c4595ef50649a91e2ca6462c27f2d42/raw/9bf129358d4f9590ceb531e904216a3c80cdd7de/example.com.conf -O $HOME/example.com.conf

set -eo pipefail # Exit when a command and any command in a pipe fails

# Install server-configs-nginx
sudo systemctl stop nginx
cd /etc || exit
sudo mv nginx nginx-previous

sudo git clone https://github.com/h5bp/server-configs-nginx.git nginx

# Copy some necessary files such as php fastcgi stuff from old location
sudo cp -R nginx-previous/snippets nginx-previous/fastcgi.conf ./nginx

# Install 7G Firewall
cd ~
wget -O 7g.zip https://perishablepress.com/downloads/18332/
aunpack 7g.zip
# FIXME: Version may change.
sudo mkdir /etc/nginx/7g && \
    sudo mv 7g/7G-Firewall-Nginx-v1.5/7g.conf /etc/nginx/7g && \
    sudo mv 7g/7G-Firewall-Nginx-v1.5/7g-firewall.conf /etc/nginx/conf.d

# Install nginx-ultimate-bad-bot-blocker
sudo wget https://raw.githubusercontent.com/mitchellkrogza/nginx-ultimate-bad-bot-blocker/master/install-ngxblocker -O /usr/local/sbin/install-ngxblocker
sudo chmod +x /usr/local/sbin/install-ngxblocker
sudo install-ngxblocker -x
# FIXME: Auto apply YES
sudo setup-ngxblocker -x -v /etc/nginx/conf.d -e conf
# Say YES to the question coming from above command.
# FIXME: Ask for email address
sudo crontab -l | { cat; echo "30 06 * * * sudo /usr/local/sbin/update-ngxblocker -e yourname@youremail.com"; } | sudo crontab -
