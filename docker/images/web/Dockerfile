FROM nginx:latest

RUN chown -R www-data:www-data /var/cache/nginx \
    && chmod -R 777 /var/cache/nginx \
    && rm /etc/nginx/conf.d/default.conf \
    && sed -i 's/nginx;/www-data;/g' /etc/nginx/nginx.conf
