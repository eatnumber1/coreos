FROM elventear/transmission

ENV ADMIN_PASS ignored
COPY settings.json /etc/transmission-daemon/settings.json
EXPOSE 9091 51413 51413/udp
USER root
VOLUME /var/lib/transmission-daemon/incomplete /var/lib/transmission-daemon/info/torrents
RUN chown debian-transmission: /etc/transmission-daemon/settings.json
USER debian-transmission
