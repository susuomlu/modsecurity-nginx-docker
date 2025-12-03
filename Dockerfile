# =======================
FROM alpine:3.19 as build

RUN apk add --no-cache \
    build-base git cmake autoconf automake libtool \
    pcre-dev zlib-dev libxml2-dev libxslt-dev yajl-dev \
    curl geoip-dev linux-headers openssl-dev libmaxminddb-dev wget

WORKDIR /opt

# Build libmodsecurity
RUN git clone --depth 1 -b v3.0.14 https://github.com/SpiderLabs/ModSecurity && \
    cd ModSecurity && git submodule init && git submodule update && \
    ./build.sh && ./configure && make -j$(nproc) && make install

# Build ModSecurity-nginx connector
RUN git clone --depth 1 https://github.com/owasp-modsecurity/ModSecurity-nginx.git

# Build nginx with SSL and ModSecurity
RUN wget https://nginx.org/download/nginx-1.28.0.tar.gz && \
    tar -xzvf nginx-1.28.0.tar.gz && \
    cd nginx-1.28.0 && \
    ./configure \
      --with-compat \
      --with-http_ssl_module \
      --add-dynamic-module=../ModSecurity-nginx && \
    make -j$(nproc) && make install

FROM alpine:3.19

RUN apk add --no-cache \
    pcre libxml2 yajl curl libstdc++ libmaxminddb geoip inotify-tools

COPY --from=build /usr/local/nginx /usr/local/nginx
COPY --from=build /usr/local/lib /usr/local/lib
COPY --from=build /usr/local/modsecurity /usr/local/modsecurity
COPY --from=build /opt/nginx-1.28.0/objs/ngx_http_modsecurity_module.so /etc/nginx/modules/

COPY ./modsec-data/nginx.conf /usr/local/nginx/conf/nginx.conf
COPY watcher.sh /usr/local/bin/watcher.sh
RUN chmod +x /usr/local/bin/watcher.sh

ENV PATH="/usr/local/nginx/sbin:$PATH"

VOLUME ["/usr/local/nginx/conf/modsec", "/var/log/modsec"]

EXPOSE 80 443

CMD ["/bin/sh", "-c", "/usr/local/bin/watcher.sh & nginx -g 'daemon off;'"]
