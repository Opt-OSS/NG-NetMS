docker run -d --name grafana -p 3000:3000 \
    --net="host" \
    -v /home/ngnms/docker-run/grafana/lib:/var/lib/grafana \
    -v /home/ngnms/docker-run/grafana/etc:/etc/grafana \
    -e "GF_SECURITY_ADMIN_PASSWORD=optoss" \
    grafana/grafana