FROM debian:stretch

LABEL maintainer="agustinmoyano@theke.io"

RUN apt update; \
    apt install -y \
        wget \
        supervisor \
        apache2 \
        gnupg2; \
    apt clean;

ARG KOHA_VERSION=stable
ARG PKG_URL=http://debian.koha-community.org/koha

RUN if [ "${PKG_URL}" = "http://debian.koha-community.org/koha" ]; then \
        wget -q -O- https://debian.koha-community.org/koha/gpg.asc | apt-key add -; \
    fi

RUN echo "deb ${PKG_URL} ${KOHA_VERSION} main" | tee /etc/apt/sources.list.d/koha.list

RUN apt update; \
    apt install -y koha-common; \
    apt clean;

RUN a2enmod rewrite cgi; \
    a2dissite 000-default; \
    echo "Listen 8081\nListen 8080" > /etc/apache2/ports.conf

RUN mkdir /docker

COPY run.sh /docker/run.sh
COPY templates /docker/templates

WORKDIR /docker

EXPOSE 8080 8081

CMD [ "./run.sh" ]