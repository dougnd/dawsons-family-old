FROM nginx:1.16-alpine

RUN rm /etc/nginx/conf.d/default.conf
COPY default.conf /etc/nginx/conf.d/default.conf
COPY index.html /var/www/html/dawsons/index.html

RUN mkdir /scripts
WORKDIR /scripts
COPY start.sh /scripts/start.sh
