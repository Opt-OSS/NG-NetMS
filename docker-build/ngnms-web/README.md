docker image used for web-interface for OPTOSS NGNMS project
-------------

####docker image based on php:5.6-apache

NGNMS optoss uses Yii 1.1 framework (this will be changed)

Added proxy module and pgsql

Added [Yii 1.1: yii-streamlog](http://www.yiiframework.com/extension/yii-streamlog/)





```bash
#!/usr/bin/env bash
docker  run  -e TERM=vt100 -it --rm --name=ngnms-web  \
	-e NGNMS_HOME=//home/ngnms/NGREADY \
	-e NGNMS_CONFIGS=//home/ngnms/NGREADY/configs \
	-e NGNMS_DB_HOST=ngnms-psql \
	-e NGNMS_DB_PORT=5432 \
	-e NGNMS_DB_USER=ngnms \
	-e NGNMS_DB_PASSWORD=optoss \
	-e NGNMS_DB=ngnms_test \
	-p 80:80 \
	--link ngnms-psql \
	vladzaitsev/ngnms-web
```


`NGNMS_DB_HOST=ngnms-psql` is the name of Postgres container.

----
If you want use Postgres running on host, replace `--link ngnms-psql` with `--net="host"` and use `NGNMS_DB_HOST=127.0.0.1` environment value  
as DB host. In whit case you may want ot edit port-mapping option `-p 80:80` to avoid conflicts with existed web-server (if you run it on host). 

for more info refer 

[From inside of a Docker container, how do I connect to the localhost of the machine?](http://stackoverflow.com/questions/24319662/from-inside-of-a-docker-container-how-do-i-connect-to-the-localhost-of-the-mach)

-----
###Customization
There are many ways to configure NGNMS running in Doker container. 
One of the options is to build you own docker image for NGNMS web service.

#####Dockerfile example: 
add custom config file to configure Yii-1.1:

```dockerfile
FROM vladzaitsev/ngnms-web
ADD src/main.php /var/www/custom_config/
```

add this line if you want to use custom php.ini file in src folder: 
```dockerfile
COPY src/php.ini /usr/local/etc/php/
```

to configure apache: 
```dockerfile
ADD src/vhost.conf /etc/apache2/sites-available/000-default.conf
```
for more info about how to configure apache or php with Docker refer to [official docker php](https://hub.docker.com/_/php/)