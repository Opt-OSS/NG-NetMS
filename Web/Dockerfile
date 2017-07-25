FROM webdevops/php-apache-dev:alpine-php5
# for php > 5.4
#RUN apt-get update && apt-get install -y build-essential libpq-dev libmcrypt-dev && \
#    a2enmod ssl rewrite && a2enmod proxy &&  a2enmod proxy_http && a2enmod proxy_connect && \
#    docker-php-ext-install -j3 pdo pdo_pgsql  mcrypt && \
#    pear install Net_IPv4 && \
#     apt-get remove --purge -y  build-essential libpq-dev libmcrypt-dev &&  apt-get autoclean && apt-get clean  && \
#     rm -rf /tmp/* /var/tmp/*    && rm -rf /var/lib/apt/lists/*
RUN apk --no-cache  add php5-pdo_pgsql php5-pear && pear install Net_IPv4
ADD php.ini /opt/docker/etc/php/php.ini
ADD grafana-proxy.conf /opt/docker/etc/httpd/conf.d/grafana-proxy.conf
ADD ./www /app
#RUN chown -R www-data:root /var/www/protected/runtime && \
#    chown -R www-data:root /var/www/protected/tmp && \
#    chown -R www-data:root /var/www/html/assets
#ENV WEB_DOCUMENT_ROOT=/var/www/html
#VOLUME ["/var/www/custom_config"]

EXPOSE 80 443



