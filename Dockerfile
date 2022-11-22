FROM nginx:latest

RUN set -x && DEBIAN_FRONTEND=noninteractive apt-get update \
  && apt-get install --no-install-recommends -y \
    build-essential \
    ca-certificates \
    dpkg-dev \
    git \
    libssl-dev \
    libpcre3-dev \
    zlib1g-dev \
    wget \
    unzip

# The actual nginx server config, this needs to get loaded last.
# Make sure you copy it to default.conf to overwrite the normal config!
#COPY config/nginx.conf /etc/nginx/nginx.conf
#COPY config/proxy.conf /etc/nginx/conf.d/default.conf
#COPY config/upstream.conf /etc/nginx/conf.d/00-upstream.conf

# Install Maxmind db library
ENV MAXMIND_VERSION=1.7.1
RUN set -x \
  && wget https://github.com/maxmind/libmaxminddb/releases/download/${MAXMIND_VERSION}/libmaxminddb-${MAXMIND_VERSION}.tar.gz \
  && tar xf libmaxminddb-${MAXMIND_VERSION}.tar.gz \
  && cd libmaxminddb-${MAXMIND_VERSION} \
  && ./configure \
  && make \
  && make check \
  && make install \
  && ldconfig

# Install nginx extension for GeoIP2. See: https://github.com/leev/ngx_http_geoip2_module
# We have to recompile nginx. To keep things simple we use the deb file + the same compile options as before.
#
# NGINX_VERSION is coming from the base container
#
# FIXME: use nginx -V to use current compile options
#        NGINX_OPTIONS=$(2>&1 nginx -V | grep 'configure arguments' | awk -F: '{print $2}') \
RUN set -x \
  && git clone https://github.com/leev/ngx_http_geoip2_module.git \
  && wget http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz \
  && tar zxvf nginx-${NGINX_VERSION}.tar.gz \
  && cd nginx-${NGINX_VERSION} \
  && git clone https://github.com/leev/ngx_http_geoip2_module \
  # && echo "deb-src http://nginx.org/packages/mainline/debian/ bullseye nginx" >> /etc/apt/sources.list \
  # && DEBIAN_FRONTEND=noninteractive apt-get update \
  # && apt-get source nginx=${NGINX_VERSION} \
  # && cd ngx_http_geoip2_module  \
  && ./configure --add-dynamic-module=../ngx_http_geoip2_module \
  && make\ 
  && make install\
  && apt-get remove --purge -y \
    build-essential \
    dpkg-dev

# Download Maxmind db version 2
# This example uses the free version from https://dev.maxmind.com/geoip/geoip2/geolite2/
#
# We only use the country db, you can add the city db and others if you want them.
#RUN set -x && mkdir -p /usr/share/geoip \
#  && wget -O /tmp/country.tar.gz http://geolite.maxmind.com/download/geoip/database/GeoLite2-Country.tar.gz \
#  && tar xf /tmp/country.tar.gz -C /usr/share/geoip --strip 1 \
#  && ls -al /usr/share/geoip/

EXPOSE 80
EXPOSE 443
