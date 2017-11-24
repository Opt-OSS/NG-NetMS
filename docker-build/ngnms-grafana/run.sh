#!/bin/bash -e

pid=0

term_handler() {
  pkill -TERM $pid
  exit
}

trap 'term_handler' SIGINT

############
#based on
# https://github.com/grafana/grafana-docker/blob/master/run.sh
# https://github.com/fabric8io/docker-grafana/blob/master/run.sh
##############

: "${GF_PATHS_DATA:=/var/lib/grafana}"
: "${GF_PATHS_LOGS:=/var/log/grafana}"
: "${GF_PATHS_PLUGINS:=/var/lib/grafana/plugins}"

chown -R grafana:grafana "$GF_PATHS_DATA" "$GF_PATHS_LOGS"
chown -R grafana:grafana /etc/grafana

if [ ! -z ${GF_AWS_PROFILES+x} ]; then
    mkdir -p ~grafana/.aws/
    touch ~grafana/.aws/credentials

    for profile in ${GF_AWS_PROFILES}; do
        access_key_varname="GF_AWS_${profile}_ACCESS_KEY_ID"
        secret_key_varname="GF_AWS_${profile}_SECRET_ACCESS_KEY"
        region_varname="GF_AWS_${profile}_REGION"

        if [ ! -z "${!access_key_varname}" -a ! -z "${!secret_key_varname}" ]; then
            echo "[${profile}]" >> ~grafana/.aws/credentials
            echo "aws_access_key_id = ${!access_key_varname}" >> ~grafana/.aws/credentials
            echo "aws_secret_access_key = ${!secret_key_varname}" >> ~grafana/.aws/credentials
            if [ ! -z "${!region_varname}" ]; then
                echo "region = ${!region_varname}" >> ~grafana/.aws/credentials
            fi
        fi
    done

    chown grafana:grafana -R ~grafana/.aws
    chmod 600 ~grafana/.aws/credentials
fi

if [ ! -f /var/lib/grafana/.configured ]; then
    grafana-cli  --pluginsDir "${GF_PATHS_PLUGINS}" plugins install grafana-simple-json-datasource
fi

if [ ! -z "${GF_INSTALL_PLUGINS}" ]; then
  OLDIFS=$IFS
  IFS=','
  for plugin in ${GF_INSTALL_PLUGINS}; do
    IFS=$OLDIFS
    grafana-cli  --pluginsDir "${GF_PATHS_PLUGINS}" plugins install ${plugin}
  done
fi

exec gosu grafana /usr/sbin/grafana-server      \
  --homepath=/usr/share/grafana                 \
  --config=/etc/grafana/grafana.ini             \
  cfg:default.log.mode="console"                \
  cfg:default.paths.data="$GF_PATHS_DATA"       \
  cfg:default.paths.logs="$GF_PATHS_LOGS"       \
  cfg:default.paths.plugins="$GF_PATHS_PLUGINS" \
  "$@" &

pid=$!

GRAFANA_USER=${GF_SECURITY_ADMIN_USER:-admin}
GRAFANA_PASSWD=${GF_SECURITY_ADMIN_PASSWORD:-admin}

HEADER_CONTENT_TYPE="Content-Type: application/json"
HEADER_ACCEPT="Accept: application/json"

echo "Waiting for Grafana to start..."
until $(curl --fail --output /dev/null --silent http://${GRAFANA_USER}:${GRAFANA_PASSWD}@localhost:3000/api/org); do
  printf "."
  sleep 1
done
echo "Grafana is up and running."

if [ ! -f /var/lib/grafana/.configured ]; then
  echo "Creating default NGNMS datasource..."
  curl -i -XPOST -H "${HEADER_ACCEPT}" -H "${HEADER_CONTENT_TYPE}" "http://${GRAFANA_USER}:${GRAFANA_PASSWD}@localhost:3000/api/datasources" -d '
  {
    "name": "DS_NGNMS",
    "label": "NGNMS",
    "type": "grafana-simple-json-datasource",
    "access": "proxy",
    "isDefault": true,
    "url": "'"${NGNMS_DATASOURCE_PROXY}"'"
  }'

  touch /var/lib/grafana/.configured
  echo ""
fi

wait $pid