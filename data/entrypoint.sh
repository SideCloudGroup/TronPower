#!/bin/sh
set -e
mkdir -p /root/.cache/crontab
CRON_JOB="* * * * * /usr/local/bin/php /var/www/html/think cronJob > /dev/null 2>&1"
cd /var/www/html || exit 1
composer upgrade --no-interaction --optimize-autoloader
chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html
php think migrate:run
if ! crontab -l 2>/dev/null | grep -Fq "$CRON_JOB"; then
    ( crontab -l 2>/dev/null; echo "$CRON_JOB" ) | crontab -
fi
crond -f &
exec "$@"
