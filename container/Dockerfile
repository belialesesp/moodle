FROM bitnamilegacy/moodle:latest
RUN sed -i "s|upload_max_filesize = 40M|upload_max_filesize = 200M|g" /opt/bitnami/php/etc/php.ini
RUN sed -i "s|post_max_size = 40M|post_max_size = 200M|g" /opt/bitnami/php/etc/php.ini
