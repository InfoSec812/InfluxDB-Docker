FROM tutum/curl:trusty
MAINTAINER Feng Honglin <hfeng@tutum.co>

# Install InfluxDB
ENV INFLUXDB_VERSION 0.8.8
RUN curl -s -o /tmp/influxdb_latest_amd64.deb https://s3.amazonaws.com/influxdb/influxdb_${INFLUXDB_VERSION}_amd64.deb && \
  dpkg -i /tmp/influxdb_latest_amd64.deb && \
  rm /tmp/influxdb_latest_amd64.deb && \
  rm -rf /var/lib/apt/lists/*

RUN apt-get update
ADD docker/config.toml /config/config.toml
RUN sed -i 's@/opt/influxdb/shared/log.txt@/data/influxdb.log@g' /config/config.toml
ADD docker/run.sh /run.sh
RUN chmod +x /*.sh

ENV PRE_CREATE_DB **None**
ENV SSL_SUPPORT **False**
ENV SSL_CERT **None**

RUN apt-get install -y nodejs npm supervisor
RUN apt-get clean
RUN npm install -g statsd statsd-influxdb-backend
RUN ln -s /usr/bin/nodejs /usr/bin/node
ADD docker/statsd.conf /config/statsd.conf
ADD docker/supervisord.d/influxdb.conf /etc/supervisor/conf.d/influxdb.conf
ADD docker/supervisord.d/statsd.conf /etc/supervisor/conf.d/statsd.conf

# Admin server
EXPOSE 8083

# HTTP API
EXPOSE 8086

# HTTPS API
EXPOSE 8084

# StatsD
EXPOSE 8125
EXPOSE 8126

# Raft port (for clustering, don't expose publicly!)
#EXPOSE 8090

# Protobuf port (for clustering, don't expose publicly!)
#EXPOSE 8099

VOLUME ["/data"]

CMD /usr/bin/supervisord -n -c /etc/supervisor/supervisord.conf
