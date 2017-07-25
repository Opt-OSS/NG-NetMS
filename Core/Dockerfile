FROM phusion/baseimage
#FROM perl:5.20
MAINTAINER Vlad Zaitsev <vladzaitsev@gmail.com>

WORKDIR /home/ngnms/NGREADY
COPY  ./nmap.sudo /etc/sudoers.d/nmap
COPY crontab.init /home/ngnms/crontab
COPY migrate-db.sh /etc/my_init.d/migrate-db.sh
COPY worker_runit.sh /etc/service/ngnms_worker/run
COPY wait-for.sh /bin/wait-for.sh
COPY update-packages.sh /update-packages.sh
RUN      chmod +x /etc/my_init.d/migrate-db.sh \
        && chmod +x /bin/wait-for.sh \
        && chmod +x /update-packages.sh \
        && chmod +x /etc/service/ngnms_worker/run \
        && mkdir -p /home/ngnms/NG_DATA

RUN /update-packages.sh   \
        && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ADD  ./NGREADY /home/ngnms/NGREADY

RUN cd /home/ngnms/NGREADY \
    && ./update-cpanm.sh

ENV NGNMS_HOME=/home/ngnms/NGREADY NGNMS_DATA=/home/ngnms/NG_DATA

VOLUME ["/home/ngnms/NG_DATA"]

CMD ["/sbin/my_init"]


