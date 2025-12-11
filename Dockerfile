FROM alpine:3.19 AS build
# Use HTTPS and official Alpine CDN
RUN echo "https://dl-cdn.alpinelinux.org/alpine/v3.19/main" > /etc/apk/repositories && \
    echo "https://dl-cdn.alpinelinux.org/alpine/v3.19/community" >> /etc/apk/repositories
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
# Build nginx with SSL and ModSecurity at /etc/nginx
RUN wget https://nginx.org/download/nginx-1.28.0.tar.gz && \
    tar -xzvf nginx-1.28.0.tar.gz && \
    cd nginx-1.28.0 && \
    ./configure \
      --prefix=/etc/nginx \
      --sbin-path=/usr/sbin/nginx \
      --modules-path=/etc/nginx/modules \
      --conf-path=/etc/nginx/nginx.conf \
      --error-log-path=/var/log/nginx/error.log \
      --http-log-path=/var/log/nginx/access.log \
      --pid-path=/var/run/nginx.pid \
      --lock-path=/var/run/nginx.lock \
      --with-compat \
      --with-http_ssl_module \
      --add-dynamic-module=../ModSecurity-nginx && \
    make -j$(nproc) && make install

FROM alpine:3.19
# Use HTTPS and official Alpine CDN
RUN echo "https://dl-cdn.alpinelinux.org/alpine/v3.19/main" > /etc/apk/repositories && \
    echo "https://dl-cdn.alpinelinux.org/alpine/v3.19/community" >> /etc/apk/repositories
RUN apk add --no-cache \
    pcre libxml2 yajl curl libstdc++ libmaxminddb geoip inotify-tools
COPY --from=build /etc/nginx /etc/nginx
COPY --from=build /usr/sbin/nginx /usr/sbin/nginx
COPY --from=build /usr/local/lib /usr/local/lib
COPY --from=build /usr/local/modsecurity /usr/local/modsecurity
# Ensure mime.types exists (copy from nginx source if not installed)
COPY --from=build /opt/nginx-1.28.0/conf/mime.types /etc/nginx/mime.types
COPY ./modsec-data/nginx.conf /etc/nginx/nginx.conf
# Create directory structure for conf.d, ssl, html, logs
RUN mkdir -p /etc/nginx/conf.d /etc/nginx/modsec /var/ssl /var/html /var/log/nginx /var/log/modsec

# Copy ModSecurity configuration files from build stage
COPY --from=build /opt/ModSecurity/modsecurity.conf-recommended /etc/nginx/modsec/modsecurity.conf
COPY --from=build /opt/ModSecurity/unicode.mapping /etc/nginx/modsec/unicode.mapping
# Enable ModSecurity rules engine
RUN sed -i 's/SecRuleEngine DetectionOnly/SecRuleEngine On/' /etc/nginx/modsec/modsecurity.conf

COPY watcher.sh /usr/local/bin/watcher.sh
RUN chmod +x /usr/local/bin/watcher.sh
VOLUME ["/etc/nginx/modsec", "/var/log/modsec", "/var/log/nginx"]
EXPOSE 80 443
CMD ["/bin/sh", "-c", "/usr/local/bin/watcher.sh & nginx -g 'daemon off;'"]
