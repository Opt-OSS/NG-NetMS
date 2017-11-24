FROM centos:7
MAINTAINER The CentOS Project <cloud-ops@centos.org>
LABEL Vendor="CentOS" \
      License=GPLv2 \
      Version=2.4.6-40



RUN yum install -y epel-release\
    && rpm -Uvh https://mirror.webtatic.com/yum/el7/webtatic-release.rpm \
    && yum -y --setopt=tsflags=nodocs install httpd mod_ssl mod_proxy \
         php56w php56w-pgsql php56w-mcrypt php56w-mbstring php56w-pdo php-pear-Net-IPv4 \
    && sed -ri ' \
    		s!^(\s*CustomLog)\s+\S+!\1 /proc/self/fd/1!g; \
    		s!^(\s*ErrorLog)\s+\S+!\1 /proc/self/fd/2!g; \
    		' /etc/httpd/conf/httpd.conf /etc/httpd/conf.d/ssl.conf \
    && yum clean all


# Simple startup script to avoid some issues observed with container restart
ADD docker/run-httpd.sh /run-httpd.sh
ADD docker/php.ini /etc/php.d/ngnms.ini
ADD docker/grafana-proxy.conf /etc/httpd/conf.d/ngnms-grafana-proxy.conf
ADD www/ /var/www
RUN chmod -v +x /run-httpd.sh \
    && chown -R root:root /var/www \
    && mkdir -p /var/www/protected/runtime && chown -R apache:apache /var/www/protected/runtime  \
    && mkdir -p /var/www/protected/tmp     && chown -R apache:apache /var/www/protected/tmp  \
    && mkdir -p /var/www/html/assets       && chown -R apache:apache /var/www/html/assets

EXPOSE 80
CMD ["/run-httpd.sh"]
