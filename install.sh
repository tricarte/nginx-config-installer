#!/usr/bin/env bash
#-----------------------------------------------------------------------------
# Install server-configs-nginx, 7G Firewall and nginx-ultimate-bad-bot-blocker
#-----------------------------------------------------------------------------

read -rp "Enter the server admin's email address: " EMAIL

SEVENGURL="https://perishablepress.com/7g-firewall-nginx/"
DOWNLOADURL=$(curl -s $SEVENGURL | sed -E -n -e "/^<div class=\"download\">$/{n;p}" \
    | cut -d"\"" -f2)

if echo "$DOWNLOADURL" | grep -E "^https://perishablepress.com/downloads/[0-9]+/?$" -q; then
    PROCEED=1
fi

# Install server-configs-nginx
sudo systemctl stop nginx
cd /etc || exit
sudo mv nginx nginx-previous

sudo git clone https://github.com/h5bp/server-configs-nginx.git nginx

# Copy some necessary files such as php fastcgi stuff from old location
sudo cp -R nginx-previous/snippets nginx-previous/fastcgi.conf ./nginx

# Create php-fpm/php-fpm.conf to be included by nginx location block
sudo mkdir /etc/nginx/php-fpm
wget -q "https://gist.githubusercontent.com/tricarte/\
559a7eeeeadf767623e856ef25847a15/raw/php-fpm.conf" \
    -O "/etc/nginx/php-fpm/php-fpm.conf"

# Nginx rate limiting configuration
echo "limit_req_zone \$binary_remote_addr zone=myzone:10m rate=5r/s;" \
    | sudo tee /etc/nginx/conf.d/rate-limiting.conf

# Install 7G Firewall
if [[ $PROCEED ]]; then
    cd ~ || exit
    wget -O 7g.zip "$DOWNLOADURL"
    if file -i 7g.zip | grep "application/zip" -q; then
        aunpack 7g.zip
        sudo mkdir /etc/nginx/7g
        find ~/7g -name '7g.conf' -exec sudo cp {} /etc/nginx/7g \;
        find ~/7g -name '7g-firewall.conf' -exec sudo cp {} /etc/nginx/conf.d \;
        if [[ ! -f /etc/nginx/7g/7g.conf ]]; then
            echo "7g.conf cannot be found in the archive."
        fi

        if [[ ! -f /etc/nginx/conf.d/7g-firewall.conf ]]; then
            echo "7g-firewall.conf cannot be found in the archive."
        fi
    else
        echo "7G Firewall cannot be downloaded."
        echo "URL was $DOWNLOADURL"
    fi
else
    echo "7G Firewall will not be installed."
    echo "URL was $DOWNLOADURL"
fi

# Install nginx-ultimate-bad-bot-blocker
sudo wget \
    https://raw.githubusercontent.com/mitchellkrogza/nginx-ultimate-bad-bot-blocker/master/install-ngxblocker \
    -O /usr/local/sbin/install-ngxblocker
sudo chmod +x /usr/local/sbin/install-ngxblocker
sudo install-ngxblocker -x
sudo setup-ngxblocker -x -v /etc/nginx/conf.d -e conf
sudo crontab -l \
    | { cat; echo "30 06 * * * sudo /usr/local/sbin/update-ngxblocker -e ${EMAIL}"; } \
    | sudo crontab -
