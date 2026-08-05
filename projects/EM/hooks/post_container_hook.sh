#!/bin/bash


function code_container_check_ords_ready() {
	local sys_credentials="${1}"

	# validate the bash variable values
	if ! cds_shared_validate_required_vars	"sys_credentials"; then
		echo "Error: ${FUNCNAME[0]}() function required bash variable validation failed" >&2
		return 1
	fi

    # query the ORDS package to check if it's available to ensure ORDS commands can be run
    sqlplus -s "${sys_credentials}" <<EOF > /dev/null 2>&1
    WHENEVER SQLERROR EXIT 1;
    BEGIN
    -- IF FALSE ensures code is compiled/checked for permissions, but never executed
    EXECUTE IMMEDIATE 'BEGIN IF FALSE THEN ORDS.ENABLE_SCHEMA(p_enabled => FALSE); END IF; END;';
    END;
    /
    EXIT;
EOF

    # Returns 0 if sqlplus exited successfully, or 1 if ORDS.ENABLE_SCHEMA couldn't be resolved
    return $?
}


function main()
{
    # reference the deploy_database_scripts_func_args variable so the values can be used
    local -n arg_ref="deploy_database_scripts_func_args"

	# store the oracle admin password in a local variable
	local sys_password="$(cat ${arg_ref[oracle_pwd_file]})"

	# define the SYS credentials for use in deployment scripts based on environment variables:
	local sys_credentials="SYS/\"${sys_password}\"@${arg_ref[dbhost]}:${arg_ref[dbport]}/${arg_ref[dbservicename]} AS SYSDBA"

    # Grant privilege so SYS can run ORDS package routines
    sqlplus -s "${sys_credentials}" <<EOF > /dev/null 2>&1
    WHENEVER SQLERROR CONTINUE;
    GRANT INHERIT PRIVILEGES ON USER SYS TO ORDS_METADATA;
    EXIT;
EOF

    # check if the $APP_SCHEMA_NAME exists in the database, if so then do not run the deployment scripts
    if code_container_check_database_initialized "${sys_credentials}" "${APP_SCHEMA_NAME}"; then
        # $APP_SCHEMA_NAME exists in the database, there is no need to run the database deployment scripts

        echo "${APP_SCHEMA_NAME} exists in the database, do not re-deploy the database and objects"

    else
        # $APP_SCHEMA_NAME does not exist in the database, run the deployment scripts
        echo "${APP_SCHEMA_NAME} does not exist in the database, run the deployment scripts"

        # define how many seconds to wait between each retry
        local retry_interval=5

        # wait for ORDS to be installed on the DB instance
        echo "wait for ORDS to be installed on the DB instance"

        # Loop until SQL*Plus returns '1' for the schema count, waiting retry_interval between each attempt
        until code_container_check_ords_ready "${sys_credentials}"; do
            echo "ORDS has not been installed yet, waiting ${retry_interval} seconds..."
            sleep "${retry_interval}"
        done

        echo "ORDS has been installed, run the custom EM database installation scripts"

        # define the database scripts map variable
        local -a DB_SCRIPTS_MAP=()

        # define the database scripts mapping using the pipe character as a delimiter
        # The elements should contain encoded values with the "|" character as the delimiter: sql path (within container)|sql script file|User Secret Name|Password Secret Name|Script Password Secrets (this can be one or more optional pipe-delimited secret names when a password is injected into the script - examples include a CREATE USER command) 
        DB_SCRIPTS_MAP+=("${BUILD_PATH}/../../projects/EM/modules/em-database/db|@dev_container_setup/create_docker_schemas.sql|oracle_admin_user|oracle_pwd|em_db_password_secret|em_app_password_secret")
        DB_SCRIPTS_MAP+=("${BUILD_PATH}/../../projects/EM/modules/em-database/db|@automated_deployments/deploy_dev_container.sql|em_db_username_secret|em_db_password_secret")
        DB_SCRIPTS_MAP+=("${BUILD_PATH}/../../projects/EM/modules/em-database/db|@automated_deployments/deploy_dev_ords_container.sql|em_app_username_secret|em_app_password_secret")

        echo "execute the EM deployment scripts"

        # execute the SYS, EM, EM_ORDS_APP schema scripts
        code_container_deploy_custom_database_scripts "deploy_database_scripts_func_args" "DB_SCRIPTS_MAP"
    fi
}

# run the main function
main

