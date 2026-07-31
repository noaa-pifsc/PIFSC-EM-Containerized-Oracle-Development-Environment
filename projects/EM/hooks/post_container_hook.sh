#!/bin/bash

echo "This is the EM post container hook"

DB_CONN="sys/YourPassword@//db-host:1521/ORCLPDB as sysdba"
RETRY_INTERVAL=5

function check_ords_schema() {
    sqlplus -s "${DB_CONN}" <<EOF
    SET HEAD OFF FEEDBACK OFF PAGESIZE 0 LINESIZE 1000;
    SELECT COUNT(*) FROM dba_users WHERE username = 'ORDS_METADATA';
    EXIT;
EOF
}

# wait for ORDS to be installed on the DB instance

# Loop until SQL*Plus returns '1' for the schema count
until [ "$(check_ords_schema | tr -d '[:space:]')" -eq "1" ]; do
    echo "ORDS schema not found yet. Retrying in ${RETRY_INTERVAL}s..."
    sleep "${RETRY_INTERVAL}"
done

echo "ORDS schema is installed, run the custom EM database installation scripts"

# define the database scripts map variable
DB_SCRIPTS_MAP=()

# define the database scripts mapping using the pipe character as a delimiter
# The elements should contain encoded values with the "|" character as the delimiter: sql path (within container)|sql script file|User Secret Name|Password Secret Name|Script Password Secrets (this can be one or more optional pipe-delimited secret names when a password is injected into the script - examples include a CREATE USER command) 
DB_SCRIPTS_MAP+=("${BUILD_PATH}/../../projects/EM/modules/em-database/db|@dev_container_setup/create_docker_schemas.sql|oracle_admin_user|oracle_pwd|em_db_password_secret|em_app_password_secret")
DB_SCRIPTS_MAP+=("${BUILD_PATH}/../../projects/EM/modules/em-database/db|@automated_deployments/deploy_dev_container.sql|em_db_username_secret|em_db_password_secret")
DB_SCRIPTS_MAP+=("${BUILD_PATH}/../../projects/EM/modules/em-database/db|@automated_deployments/deploy_dev_app_container.sql|em_app_username_secret|em_app_password_secret")


echo "execute the EM deployment scripts"

# execute the SYS, EM, EM_ORDS_APP schema scripts
code_container_deploy_custom_database_scripts "deploy_database_scripts_func_args" "DB_SCRIPTS_MAP"