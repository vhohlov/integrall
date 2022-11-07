FROM ubuntu:22.04

WORKDIR /var/www
ARG NODE_VERSION=16
ENV TZ=UTC

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt-get update \
    && apt-get install -y gosu ca-certificates zip unzip git libcap2-bin python2 apache2 libapache2-mod-php mysql-client\
    && apt-get install -y gnupg && mkdir -p ~/.gnupg  chmod 600 ~/.gnupg \
    && echo "disable-ipv6" >> ~/.gnupg/dirmngr.conf \
    && echo "keyserver hkp://keyserver.ubuntu.com:80" >> ~/.gnupg/dirmngr.conf \
    && gpg --recv-key 0x14aa40ec0831756756d7f66c4f4ea0aae5267a6c \
    && gpg --export 0x14aa40ec0831756756d7f66c4f4ea0aae5267a6c > /usr/share/keyrings/ppa_ondrej_php.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/ppa_ondrej_php.gpg] https://ppa.launchpadcontent.net/ondrej/php/ubuntu jammy main" > /etc/apt/sources.list.d/ppa_ondrej_php.list \
    && apt-get update \
    && apt-get install -y php8.1-cli php8.1-dev \
        php8.1-gd php8.1-curl \
        php8.1-imap php8.1-mysql php8.1-sqlite3  php8.1-mbstring \
        php8.1-xml php8.1-zip php8.1-bcmath php8.1-soap \
        php8.1-intl php8.1-readline \
        php8.1-ldap \
        php8.1-msgpack php8.1-igbinary php8.1-redis php8.1-swoole \
        php8.1-pcov php8.1-xdebug \
    && php -r "readfile('https://getcomposer.org/installer');" | php -- --install-dir=/usr/bin/ --filename=composer

RUN curl -sLS https://deb.nodesource.com/setup_$NODE_VERSION.x | bash - \
    && apt-get install -y nodejs \
    && npm install -g npm \
    && curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | gpg --dearmor | tee /usr/share/keyrings/yarn.gpg >/dev/null \
    && echo "deb [signed-by=/usr/share/keyrings/yarn.gpg] https://dl.yarnpkg.com/debian/ stable main" > /etc/apt/sources.list.d/yarn.list \
    && apt-get update \
    && apt-get install -y yarn 

RUN apt-get -y autoremove && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN setcap "cap_net_bind_service=+ep" /usr/bin/php8.1

RUN groupadd --force sails && useradd -ms /bin/bash --no-user-group -g sails -u 1337 sail
RUN echo "Listen 8080" >> /etc/apache2/ports.conf \
    && chown -R www-data:www-data /var/www \
    && a2enmod rewrite

COPY docker/000-default.conf /etc/apache2/sites-available/000-default.conf
COPY docker/php.ini /etc/php/8.1/cli/conf.d/99-sail.ini
COPY docker/start-container /usr/local/bin/start-container
COPY . . 

RUN composer install \
#    && php artisan config:cache \
    && chmod -R 777 . \
    && php artisan breeze:install \
    && npm install
    
RUN npm run dev

RUN chmod +x /usr/local/bin/start-container

EXPOSE 8080

ENTRYPOINT ["start-container"]
