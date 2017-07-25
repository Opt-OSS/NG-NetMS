FROM vladzaitsev/ngnms-core:3.5b2
ARG ngnms_uid
ARG ngnms_gid

#RUN  groupadd -g $ngnms_gid ngnms
RUN useradd -u $ngnms_uid -G sudo -s /bin/bash ngnms && chown -R ngnms:ngnms  /home/ngnms/NGREADY && chmod g+w -R /home/ngnms/NGREADY/Shared
USER ngnms
CMD ["/sbin/my_init"]
