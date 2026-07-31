#!/bin/bash
set -e # Exit immediately on error

# ords_startup.sh runs as the entrypoint to the CODE-ords.yml configuration file

# Define resource paths
CONFIG_DIR="/etc/ords/config"
PW_FILE="/run/secrets/oracle_pwd"

# validate the database admin password secret exists
if [ ! -f "${PW_FILE}" ]; then
	echo "Error: Secret oracle_pwd was not found."
	exit 1
fi

# store the credentials and connection string
SYS_PWD=$(cat "${PW_FILE}")
DB_CONN="${DBHOST}:${DBPORT}/${DBSERVICENAME}"

# wait for the code-db-ords-deploy Apex installation/upgrade process to finish
echo "Waiting for database deployment to finish:"
while [ ! -f /opt/oracle/ords/static/deployments/.deploy_ready_${DEPLOY_ID} ]; do
  sleep 5
  echo "Still waiting for database deployment to finish..."
done
echo "ORDS/Apex installation/upgrade completed"

# define the password variable values
export ORACLE_PWD=$(cat "${PW_FILE}")
export ORDS_PWD=$(cat "${PW_FILE}")
export ORACLE_USR_PWD=$(cat "${PW_FILE}")

echo "Checking database readiness at ${DB_CONN}..."
until sql -L "sys/${SYS_PWD}@//${DB_CONN} as sysdba" <<EOF > /dev/null 2>&1
BEGIN
  -- query for the ORDS_PUBLIC_USER and APEX_PUBLIC_USER accounts, loop through the schemas and set the password
  FOR rec in (select username from dba_users WHERE username IN ('ORDS_PUBLIC_USER', 'APEX_PUBLIC_USER')) 
  LOOP
	-- attempt to set the password for the current schema
    EXECUTE IMMEDIATE 'ALTER USER '||rec.username||' IDENTIFIED BY "${SYS_PWD}" ACCOUNT UNLOCK';
  END LOOP;
END;
/
EXIT;
EOF
do
  echo "Database is not ready yet, retrying connection..."
  sleep 2
done

echo "Apex/ORDS credentials have been synchronized"

# create the default database pool configuration folder
mkdir -p "${CONFIG_DIR}/databases/default"

# generate the pool.xml configuration file with the database settings from the environment configuration variables
echo "generate the pool.xml configuration file"
cat <<EOF > "${CONFIG_DIR}/databases/default/pool.xml"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE properties SYSTEM "http://java.sun.com/dtd/properties.dtd">
<properties>
<comment>Generated dynamically for ORDS container based on database configuration values</comment>
<entry key="db.connectionType">basic</entry>
<entry key="db.hostname">${DBHOST}</entry>
<entry key="db.port">${DBPORT}</entry>
<entry key="db.servicename">${DBSERVICENAME}</entry>
<entry key="db.username">ORDS_PUBLIC_USER</entry>
<entry key="feature.sdw">true</entry>
<entry key="plsql.gateway.mode">proxied</entry>
<entry key="restEnabledSql.active">true</entry>
<entry key="security.requestValidationFunction">ords_util.authorize_plsql_gateway</entry>
</properties>
EOF

# create the directory for the global ORDS configuration
mkdir -p "${CONFIG_DIR}/global"

# generate the global settings.xml configuration file
echo "generate the global settings.xml configuration file"
cat <<EOF > "${CONFIG_DIR}/global/settings.xml"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE properties SYSTEM "http://java.sun.com/dtd/properties.dtd">
<properties>
<comment>Generated dynamically for ORDS container based on database configuration values</comment>
<entry key="database.api.enabled">true</entry>
<entry key="mongo.enabled">true</entry>
<entry key="standalone.access.log">/tmp/ords_access_logs/</entry>
<entry key="standalone.static.context.path">/i</entry>
<entry key="standalone.static.path">/opt/oracle/ords/static</entry>
</properties>      
EOF

# define the db.password securely with the secret value
echo "define the db password securely with the specified secret value"
ords --config "${CONFIG_DIR}" config secret --password-stdin db.password < "${PW_FILE}"

echo "Starting official ORDS entrypoint"
exec docker-entrypoint.sh "$@"