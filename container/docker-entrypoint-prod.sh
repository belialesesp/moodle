#!/usr/bin/env bash
set -e

# Basic permission fix
chown -R www-data:www-data /var/www/moodle /var/www/moodledata || true

# If MOODLE_DOWNLOAD_URL provided, download and extract (dev convenience)
if [ -n "${MOODLE_DOWNLOAD_URL}" ] && [ ! -f /var/www/moodle/config.php ]; then
  echo "Downloading Moodle from ${MOODLE_DOWNLOAD_URL}..."
  curl -fsSL "${MOODLE_DOWNLOAD_URL}" -o /tmp/moodle.tgz
  tar -xzf /tmp/moodle.tgz -C /var/www --strip-components=1
  rm /tmp/moodle.tgz
  chown -R www-data:www-data /var/www/moodle
fi

# Optionally enable XDEBUG based on env var
if [ "${XDEBUG_ENABLED}" = "0" ] || [ "${XDEBUG_ENABLED}" = "false" ]; then
  echo "Disabling Xdebug"
  phpdismod xdebug || true
else
  echo "Xdebug enabled"
fi

# Start cron in background for dev convenience (runs every minute)
if [ "${DEV_CRON}" = "1" ] || [ "${DEV_CRON}" = "true" ]; then
  service cron start || true
fi

exec "$@"
