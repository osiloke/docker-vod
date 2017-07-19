FROM alpine:3.6 as build

RUN apk add --no-cache curl build-base openssl openssl-dev zlib-dev linux-headers pcre-dev ffmpeg ffmpeg-dev
RUN mkdir nginx nginx-vod-module

ENV NGINX_VERSION 1.12.1
ENV VOD_MODULE_VERSION 1.18

RUN curl -sL https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz | tar -C nginx --strip 1 -xz
RUN curl -sL https://github.com/kaltura/nginx-vod-module/archive/${VOD_MODULE_VERSION}.tar.gz | tar -C nginx-vod-module --strip 1 -xz

WORKDIR nginx
RUN ./configure --prefix=/usr/local/nginx \
	--add-module=../nginx-vod-module \
	--with-file-aio \
	--with-threads \
	--with-cc-opt="-O3"
RUN make
RUN make install

FROM alpine:3.5
RUN apk add --no-cache ca-certificates openssl pcre zlib ffmpeg
COPY --from=build /usr/local/nginx /usr/local/nginx
RUN rm -rf /usr/local/nginx/html/* /usr/local/nginx/conf/*.default

WORKDIR /usr/local/nginx
# # Add rtmp config wildcard inclusion
RUN mkdir -p /usr/local/nginx/strm.d
# Copy nginx conf for streaming
COPY nginx.conf /usr/local/nginx/conf/nginx.conf

COPY default.conf /usr/local/nginx/strm.d/default.conf
COPY crossdomain.xml /usr/local/nginx/html/crossdomain.xml

VOLUME ["/usr/local/nginx/logs"]

VOLUME ["/videos"]

ENTRYPOINT ["/usr/local/nginx/sbin/nginx"]
EXPOSE 80
CMD ["-g", "daemon off;"]