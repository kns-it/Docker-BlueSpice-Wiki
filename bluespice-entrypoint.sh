#!/bin/bash

if [ ! -f /config/LocalSettings.php ]; then
        echo "Creating initial LocalSettings.php and initializing database..."
        php maintenance/install.php --server "${WIKI_URL}" \
                                                      --dbuser "${DB_USER}" \
                                                      --dbpass "${DB_PASS}" \
                                                      --dbname "${DB_NAME}" \
                                                      --dbport ${DB_PORT} \
                                                      --dbserver "${DB_SERVER}" \
                                                      --dbtype mysql \
                                                      --pass "${ADMIN_PASS}" \
                                                      --scriptpath "" \
                                                      --confpath /config/ \
                                                      ${WIKI_NAME} \
                                                      ${ADMIN_LOGIN}
fi

if [ -f /config/LocalSettings.php ]; then
        settings_contains_bluespice_require=$( cat /config/LocalSettings.php | grep 'LocalSettings.BlueSpice.php' | wc -l )

        if [ "${settings_contains_bluespice_require}" -ne "1" ]; then
                echo "BlueSpice include is missing in LocalSettings.php. Adding it for you..."
                echo 'require_once "$IP/LocalSettings.BlueSpice.php";' >> /config/LocalSettings.php
        fi
        
        echo "Copying persistent LocalSettings.php to web directory..."
        cp -f /config/LocalSettings.php /var/www/html/

        echo "Copying external extensions to web directory..."
        cp -rf /extensions/* /var/www/html/extensions/

        echo "Run update script to ensure that database is up to date..."
        php maintenance/update.php --quick

        echo "Correct permissions to ensure that web server is able to access the web directory..."
        chown -R www-data:www-data /var/www/html

        echo "Starting Apache. Enjoy your BlueSpice wiki!"
        apache2-foreground
else
        echo "Setup failed exiting now!"
fi