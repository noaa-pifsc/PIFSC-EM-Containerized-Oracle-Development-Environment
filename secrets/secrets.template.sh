#--- Credentials ---

# define the default admin user for Oracle
ORACLE_ADMIN_USER="SYS"

# Set your oracle administrator password here: SYS and SYSTEM database schema passwords, APEX administrator password (workspace = INTERNAL, user = ADMIN), and the ORDS_PUBLIC_USER password
ORACLE_PWD='[DEFINE_PASSWORD_HERE]'

# define any database/apex credentials necessary to deploy the database schemas and/or applications
EM_DB_USER="PIFSC_EM"
EM_DB_PWD="[DEFINE_PASSWORD_HERE]"

EM_APP_USER="PIFSC_EM_ORDS"
EM_APP_PWD="[DEFINE_PASSWORD_HERE]"

# EM app settings
EM_APP_CLIENT_ID="[FIREBASE CLIENT ID]"
EM_APP_ISSUER="[FIREBASE_APP_ISSUER_URL]"
EM_APP_AUDIENCE="[APP_AUDIENCE]"
EM_APP_JWK_URL="[APP_JWK_URL]"
EM_APP_SUPPORT_EMAIL="[APP_SUPPORT_EMAIL]"