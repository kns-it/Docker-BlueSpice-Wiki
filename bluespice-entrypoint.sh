#!/bin/bash

if [ ! -f /config/LocalSettings.php ]; then
        echo ""
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

settings_contains_bluespice_require=$( cat /config/LocalSettings.php | grep 'LocalSettings.BlueSpice.php' | wc -l )

if [ "${settings_contains_bluespice_require}" -ne "1" ]; then
        echo 'require_once "$IP/LocalSettings.BlueSpice.php";' >> /config/LocalSettings.php
fi

cp -f /config/LocalSettings.php /var/www/html/

cp -rf /extensions/* /var/www/html/extensions/

php maintenance/update.php --quick

chown -R www-data:www-data /var/www/html

apache2-foreground