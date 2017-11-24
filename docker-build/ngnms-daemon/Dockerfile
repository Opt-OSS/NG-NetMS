FROM vladzaitsev/ngnms-collector:3.6
#Create db-connect config
ARG NGNMS_UID=1000


COPY ./*.sh /
COPY ./rules.txt /rules/rules.txt
RUN chmod +x  /wait-for.sh  \
    && chmod +x start.sh \
    && adduser -D -u $NGNMS_UID ngnms \
    && mkdir -p /home/ngnms/NG_DATA && mkdir -p /home/ngnms/NGREADY \
    && chown -R ngnms:ngnms  /home/ngnms/NGREADY /home/ngnms/NG_DATA \
    && chmod g+w -R /home/ngnms/NG_DATA

ENV NGNMS_HOME="/home/ngnms/NGREADY" NGNMS_DATA="/home/ngnms/NG_DATA"
VOLUME ["/rules","/home/ngnms/NG_DATA"]

ENTRYPOINT ["/start.sh"]