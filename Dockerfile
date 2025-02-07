FROM debian:bookworm

ARG KOHA_COMMON_DEB_URL
ARG KOHA_VERSION=23.05
ARG PKG_URL=https://debian.koha-community.org/koha

LABEL maintainer="agustinmoyano@theke.io"

RUN    apt update \
    && apt install -y \
            wget \
            supervisor \
            apache2 \
            gnupg2 \
            apt-transport-https \
    && rm -rf /var/cache/apt/archives/* \
    && rm -rf /var/lib/apt/lists/*

RUN if [ "${PKG_URL}" = "https://debian.koha-community.org/koha" ]; then \
        wget -q -O- https://debian.koha-community.org/koha/gpg.asc | apt-key add -; \
    fi

RUN echo "deb ${PKG_URL} ${KOHA_VERSION} main" | tee /etc/apt/sources.list.d/koha.list

# Install Koha
RUN if [ -z "${KOHA_COMMON_DEB_URL}" ]; then \
        apt update \
         && apt install -y koha-common \
         && rm -rf /var/cache/apt/archives/* \
         && rm -rf /var/lib/apt/lists/* \
    ; else \
        apt update \
         && apt install -y koha-common libreadonly-xs-perl\
         && wget ${KOHA_COMMON_DEB_URL} \
         && dpkg -i koha-common*.deb \
         && rm -f koha-common*.deb \
         && rm -rf /var/cache/apt/archives/* \
         && rm -rf /var/lib/apt/lists/* \
    ; fi

RUN a2enmod rewrite \
            headers \
            proxy_http \
            cgi \
    && a2dissite 000-default \
    && echo "Listen 8081\nListen 8080" > /etc/apache2/ports.conf

# Adjust apache configuration files
RUN sed -e "s/unix.*\/\/localhost/http\:\/\/koha\:5000/g" /etc/koha/apache-shared-intranet-plack.conf > /etc/koha/apache-shared-intranet-plack.conf.new \
    && sed -e "s/unix.*\/\/localhost/http\:\/\/koha\:5000/g" /etc/koha/apache-shared-opac-plack.conf  > /etc/koha/apache-shared-opac-plack.conf.new \
    && mv /etc/koha/apache-shared-intranet-plack.conf.new /etc/koha/apache-shared-intranet-plack.conf \
    && mv /etc/koha/apache-shared-opac-plack.conf.new /etc/koha/apache-shared-opac-plack.conf

RUN mkdir /docker

COPY run.sh /docker/run.sh
COPY templates /docker/templates

WORKDIR /docker

EXPOSE 8080 8081

CMD [ "./run.sh" ]
