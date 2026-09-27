# syntax=docker/dockerfile:1
ARG PHP_VERSION=8.4

FROM php:${PHP_VERSION}-fpm-alpine AS base

COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/
RUN install-php-extensions intl pdo_pgsql opcache zip

RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"
COPY docker/php/opcache.ini "$PHP_INI_DIR/conf.d/opcache.ini"

WORKDIR /var/www/html

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

COPY composer.json composer.lock symfony.lock ./
RUN composer install --no-dev --no-scripts --no-autoloader --no-interaction --prefer-dist \
    && composer clear-cache

COPY . .

RUN composer dump-autoload --optimize --no-dev --classmap-authoritative \
    && composer dump-env prod \
    && mkdir -p var/cache var/log config/jwt \
    && chown -R www-data:www-data var

ENV APP_ENV=prod
USER www-data
EXPOSE 9000
CMD ["php-fpm"]
