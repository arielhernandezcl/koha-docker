FROM debian:stretch
ARG KOHA_COMMMON_DEB_URL
ENV KOHA_COMMON_DEB=$KOHA_COMMMON_DEB_URL

LABEL maintainer="agustinmoyano@theke.io"

RUN    apt update \
    && apt install -y \
            wget \
            supervisor \
            apache2 \
            gnupg2 \
            apt-transport-https \
    && apt clean

ARG KOHA_VERSION=19.11
ARG PKG_URL=https://debian.koha-community.org/koha

RUN if [ "${PKG_URL}" = "https://debian.koha-community.org/koha" ]; then \
        wget -q -O- https://debian.koha-community.org/koha/gpg.asc | apt-key add -; \
    fi

RUN echo "deb ${PKG_URL} ${KOHA_VERSION} main" | tee /etc/apt/sources.list.d/koha.list

# Install Koha
RUN if [ -z "${KOHA_COMMMON_DEB}" ]; then \
        apt update \
         && apt install -y koha-common \
         && apt clean \
    ; else \
        apt update \
         && wget ${KOHA_COMMON_DEB} \
         && dpkg -i koha-common*.deb \
         && apt clean \
    ; fi

RUN    a2enmod rewrite \
           headers \
           proxy_http \
           cgi \
    && a2dissite 000-default \
    && echo "Listen 8081\nListen 8080" > /etc/apache2/ports.conf

RUN mkdir /docker

COPY run.sh /docker/run.sh
COPY templates /docker/templates

WORKDIR /docker

EXPOSE 8080 8081

CMD [ "./run.sh" ]
