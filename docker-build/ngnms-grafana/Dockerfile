FROM grafana/grafana:4.3.2
# Based on https://github.com/fabric8io/docker-grafana/blob/master/Dockerfile
MAINTAINER Vlad Zaitsev <vladzaitsev@gmail.com>

ENTRYPOINT ["/run.sh"]

ENV GF_AUTH_ANONYMOUS_ENABLED=false \
    GF_DASHBOARDS_JSON_ENABLED=true \
    GF_DASHBOARDS_JSON_PATH=/dashboards \
    GF_LOG_MODE=console \
    NGNMS_DATASOURCE_PROXY="http://web/grafana_api/"

RUN apt-get update && \
    apt-get install -y curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    chmod 777 /var/lib/grafana /usr/share/grafana/

ADD run.sh /run.sh
ADD dashboards /dashboards
RUN chmod 777 /dashboards && chmod 666 /dashboards/* && chmod +x  /run.sh

#USER grafana