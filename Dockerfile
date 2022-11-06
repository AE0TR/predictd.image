FROM alpine:3.15 as builder

WORKDIR /var/build

RUN apk update
RUN apk upgrade
RUN apk add --no-cache linux-headers musl-dev libusb-dev ncurses-dev
RUN apk add --no-cache build-base git make cmake pkgconf autoconf libtool

RUN git clone https://github.com/kd2bd/predict . \
    && echo "y" | ./configure

FROM alpine:3.15

RUN apk --no-cache add ncurses \
    && echo "predict    1210/udp" > /etc/services \
    && mkdir /data

COPY --from=builder /usr/local/bin/* /usr/local/bin/

COPY kepler-update /usr/local/bin/
COPY root.crontab /root/

COPY *.tle *.qth /data/

RUN crontab /root/root.crontab \
    && chmod +x /usr/local/bin/kepler-update

VOLUME [ "/data" ]

EXPOSE 1210/udp

ENV TLE_FILE predict.tle
ENV QTH_FILE predict.qth

ENTRYPOINT [ "sh", "-c","predict -s -q /data/${QTH_FILE} -t /data/${TLE_FILE}"]
