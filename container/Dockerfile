# Dockerfile de Produção - Moodle 5.1+ com PHP-FPM
# Universidade Nós Periféricos

# ============================================================================
# Stage 1: Builder - Compilação e download do Moodle
# ============================================================================
ARG PHP_VERSION=8.2
FROM php:${PHP_VERSION}-fpm AS builder

ARG DEBIAN_FRONTEND=noninteractive
ARG MOODLE_VERSION=MOODLE_501_STABLE

LABEL maintainer="Secretaria Nacional de Periferias"
LABEL stage="builder"

# Instalar dependências de build
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    unzip \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Clonar Moodle do repositório oficial
WORKDIR /build
# Usar main branch para ter estrutura 5.1+ mais recente
RUN git clone --depth=1 --branch=main \
    https://github.com/moodle/moodle.git . \
    && rm -rf .git \
    && echo "Moodle version:" && grep '$release' version.php || true

# ============================================================================
# Stage 2: Extensões PHP
# ============================================================================
FROM php:${PHP_VERSION}-fpm AS php-extensions

ARG DEBIAN_FRONTEND=noninteractive

# Instalar dependências para compilar extensões PHP
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libicu-dev \
    libzip-dev \
    libxml2-dev \
    libxslt1-dev \
    libpq-dev \
    libldap2-dev \
    && rm -rf /var/lib/apt/lists/*

# Compilar e instalar extensões PHP necessárias para Moodle
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
    gd \
    mysqli \
    pdo_mysql \
    pdo_pgsql \
    pgsql \
    zip \
    intl \
    soap \
    opcache \
    exif \
    bcmath \
    sockets

# Instalar Redis via PECL
RUN pecl install redis \
    && docker-php-ext-enable redis

# ============================================================================
# Stage 3: Imagem Final de Produção
# ============================================================================
FROM php:${PHP_VERSION}-fpm AS production

ARG DEBIAN_FRONTEND=noninteractive

LABEL maintainer="Secretaria Nacional de Periferias"
LABEL description="Moodle 5.1+ PHP-FPM - Universidade Nós Periféricos"
LABEL version="5.1"

# Instalar apenas runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpng-dev \
    libjpeg-dev \
    libfreetype6 \
    libicu-dev \
    libzip-dev \
    libxml2 \
    libxslt1.1 \
    libpq-dev \
    libldap2-dev \
    ghostscript \
    cron \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Copiar extensões PHP compiladas do stage anterior
COPY --from=php-extensions /usr/local/lib/php/extensions/ /usr/local/lib/php/extensions/
COPY --from=php-extensions /usr/local/etc/php/conf.d/ /usr/local/etc/php/conf.d/

# Variáveis de ambiente
ENV MOODLE_DIR=/var/www/moodle \
    MOODLE_DATA=/var/www/moodledata \
    PHP_UPLOAD_MAX_FILESIZE=200M \
    PHP_POST_MAX_SIZE=200M \
    PHP_MEMORY_LIMIT=512M \
    PHP_MAX_EXECUTION_TIME=300

# Criar estrutura de diretórios
RUN mkdir -p ${MOODLE_DIR} ${MOODLE_DATA} \
    && chown -R www-data:www-data ${MOODLE_DIR} ${MOODLE_DATA} \
    && chmod -R 755 ${MOODLE_DIR} ${MOODLE_DATA}

# Copiar código do Moodle do builder
COPY --from=builder --chown=www-data:www-data /build ${MOODLE_DIR}

# Configurações PHP otimizadas para produção
RUN { \
    echo '[PHP]'; \
    echo 'expose_php = Off'; \
    echo 'max_execution_time = 300'; \
    echo 'max_input_time = 300'; \
    echo 'memory_limit = 512M'; \
    echo 'post_max_size = 200M'; \
    echo 'upload_max_filesize = 200M'; \
    echo 'max_input_vars = 5000'; \
    echo 'date.timezone = America/Sao_Paulo'; \
    echo 'display_errors = Off'; \
    echo 'log_errors = On'; \
    echo 'error_log = /var/log/php_errors.log'; \
    echo ''; \
    echo '[Session]'; \
    echo 'session.cookie_httponly = 1'; \
    echo 'session.cookie_secure = 1'; \
    echo 'session.use_strict_mode = 1'; \
} > /usr/local/etc/php/conf.d/moodle-custom.ini

# Configurações OPcache para produção
RUN { \
    echo '[opcache]'; \
    echo 'opcache.enable = 1'; \
    echo 'opcache.memory_consumption = 256'; \
    echo 'opcache.interned_strings_buffer = 16'; \
    echo 'opcache.max_accelerated_files = 10000'; \
    echo 'opcache.revalidate_freq = 60'; \
    echo 'opcache.fast_shutdown = 1'; \
    echo 'opcache.validate_timestamps = 1'; \
    echo 'opcache.save_comments = 0'; \
} > /usr/local/etc/php/conf.d/opcache-recommended.ini

# Configurar PHP-FPM
RUN { \
    echo '[www]'; \
    echo 'pm = dynamic'; \
    echo 'pm.max_children = 50'; \
    echo 'pm.start_servers = 10'; \
    echo 'pm.min_spare_servers = 5'; \
    echo 'pm.max_spare_servers = 20'; \
    echo 'pm.max_requests = 500'; \
    echo 'pm.status_path = /status'; \
    echo 'ping.path = /ping'; \
    echo 'ping.response = pong'; \
    echo 'catch_workers_output = yes'; \
    echo 'clear_env = no'; \
} >> /usr/local/etc/php-fpm.d/www.conf

# Criar link simbólico para /public (Moodle 5.1+)
# O nginx vai servir de /var/www/moodle/public
RUN if [ -d ${MOODLE_DIR}/public ]; then \
        ln -sf ${MOODLE_DIR}/public /var/www/html; \
        echo "Usando estrutura /public do Moodle 5.1+"; \
    else \
        ln -sf ${MOODLE_DIR} /var/www/html; \
        echo "Usando estrutura raiz (Moodle < 5.1)"; \
    fi

# Script de entrypoint
COPY docker-entrypoint-prod.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint-prod.sh

# Configurar cron para tarefas do Moodle (executa a cada minuto)
RUN echo '* * * * * www-data /usr/local/bin/php ${MOODLE_DIR}/admin/cli/cron.php >/dev/null 2>&1' \
    > /etc/cron.d/moodle-cron \
    && chmod 0644 /etc/cron.d/moodle-cron

WORKDIR ${MOODLE_DIR}

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=60s --retries=3 \
    CMD SCRIPT_NAME=/ping SCRIPT_FILENAME=/ping REQUEST_METHOD=GET \
    cgi-fcgi -bind -connect 127.0.0.1:9000 || exit 1

EXPOSE 9000

# Não usar USER aqui - entrypoint vai gerenciar usuários
ENTRYPOINT ["/usr/local/bin/docker-entrypoint-prod.sh"]
CMD ["php-fpm", "-F"]