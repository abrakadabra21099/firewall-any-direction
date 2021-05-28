FROM alpine:3.13.5
LABEL maintainer="4i! aka \$oRRy <abrakadabra21099@gmail.com>"
LABEL description="Firewall for any direction with protection against various attacks."
RUN apk add --no-cache iptables
ENV EXT_IF tun0
ENV INT_IF eth0
COPY entrypoint.sh firewall.sh /
ENTRYPOINT /entrypoint.sh 
