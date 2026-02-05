#!/usr/bin/env bash
set -eo pipefail

echo "=== Moodle Production Container - Universidade Nós Periféricos ==="

# Variáveis de ambiente com defaults
: ${MOODLE_DIR:=/var/www/moodle}
: ${MOODLE_DATA:=/var/www/moodledata}
: ${SKIP_PERMISSIONS:=false}

# Função para aguardar banco de dados
wait_for_db() {
    if [ -n "${DB_HOST}" ]; then
        echo "Aguardando banco de dados ${DB_HOST}:${DB_PORT:-3306}..."
        timeout=60
        while ! timeout 1 bash -c "cat < /dev/null > /dev/tcp/${DB_HOST}/${DB_PORT:-3306}" 2>/dev/null; do
            timeout=$((timeout - 1))
            if [ $timeout -le 0 ]; then
                echo "ERRO: Timeout ao aguardar banco de dados"
                exit 1
            fi
            sleep 1
        done
        echo "Banco de dados disponível!"
    fi
}

# Aguardar banco se configurado
wait_for_db

# Criar config.php se não existir e variáveis estiverem definidas
if [ ! -f "${MOODLE_DIR}/config.php" ] && [ -n "${DB_HOST}" ]; then
    echo "Criando config.php..."
    
    : ${DB_TYPE:=mariadb}
    : ${DB_PORT:=3306}
    : ${DB_NAME:=moodle}
    : ${DB_USER:=moodle}
    : ${DB_PREFIX:=mdl_}
    : ${MOODLE_URL:=http://localhost}
    
    cat > ${MOODLE_DIR}/config.php <<'PHPEOF'
<?php
unset($CFG);
global $CFG;
$CFG = new stdClass();

$CFG->dbtype    = getenv('DB_TYPE') ?: 'mariadb';
$CFG->dblibrary = 'native';
$CFG->dbhost    = getenv('DB_HOST');
$CFG->dbname    = getenv('DB_NAME') ?: 'moodle';
$CFG->dbuser    = getenv('DB_USER') ?: 'moodle';
$CFG->dbpass    = getenv('DB_PASSWORD');
$CFG->prefix    = getenv('DB_PREFIX') ?: 'mdl_';

$CFG->dboptions = array(
    'dbpersist' => false,
    'dbsocket'  => false,
    'dbport'    => getenv('DB_PORT') ?: '3306',
    'dbcollation' => 'utf8mb4_unicode_ci',
);

$CFG->wwwroot   = getenv('MOODLE_URL') ?: 'http://localhost';
$CFG->dataroot  = getenv('MOODLE_DATA') ?: '/var/www/moodledata';
$CFG->admin     = 'admin';

$CFG->directorypermissions = 0755;

// Performance tuning
$CFG->cachejs = true;
$CFG->cachetemplates = true;

// Redis session handler (se disponível)
if (getenv('REDIS_HOST')) {
    $CFG->session_handler_class = '\core\session\redis';
    $CFG->session_redis_host = getenv('REDIS_HOST');
    $CFG->session_redis_port = getenv('REDIS_PORT') ?: 6379;
    $CFG->session_redis_database = getenv('REDIS_DB') ?: 0;
    if (getenv('REDIS_PASSWORD')) {
        $CFG->session_redis_auth = getenv('REDIS_PASSWORD');
    }
}

// Redis cache (se disponível)
if (getenv('REDIS_HOST')) {
    $CFG->alternative_cache_factory_class = 'cache_factory';
}

require_once(__DIR__ . '/lib/setup.php');
PHPEOF
    
    echo "Config.php criado!"
fi

# Ajustar permissões (opcional, pode ser skip para performance)
if [ "${SKIP_PERMISSIONS}" != "true" ]; then
    echo "Ajustando permissões..."
    chown -R www-data:www-data ${MOODLE_DIR} ${MOODLE_DATA} 2>/dev/null || true
    chmod -R 755 ${MOODLE_DATA} 2>/dev/null || true
fi

# Iniciar cron em background
if [ "${ENABLE_CRON}" = "true" ]; then
    echo "Iniciando cron..."
    cron
fi

# Informações de debug (apenas se DEBUG=true)
if [ "${DEBUG}" = "true" ]; then
    echo "=== Informações de Debug ==="
    echo "MOODLE_DIR: ${MOODLE_DIR}"
    echo "MOODLE_DATA: ${MOODLE_DATA}"
    echo "DB_TYPE: ${DB_TYPE}"
    echo "DB_HOST: ${DB_HOST}"
    echo "DB_NAME: ${DB_NAME}"
    echo "PHP Version: $(php -v | head -n 1)"
    echo "Extensions: $(php -m | tr '\n' ' ')"
fi

echo "=== Iniciando PHP-FPM ==="
exec "$@"
