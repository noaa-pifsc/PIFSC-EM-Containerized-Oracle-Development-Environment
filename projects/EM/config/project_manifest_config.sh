#!/bin/bash

	# define the array of compose files that are used by the individual projects (specify the path relative to the core/build directory
	COMPOSE_FILES+=("../../projects/EM/build/em_secrets.yml")
	
	# add the secrets
	SECRET_MAPPING_ARR+=(
		["em_db_username_secret"]="EM_DB_USER"
		["em_db_password_secret"]="EM_DB_PWD"
		["em_app_username_secret"]="EM_APP_USER"
		["em_app_password_secret"]="EM_APP_PWD"
		["em_app_client_id"]="EM_APP_CLIENT_ID"
		["em_app_issuer"]="EM_APP_ISSUER"
		["em_app_audience"]="EM_APP_AUDIENCE"
		["em_app_jwk_url"]="EM_APP_JWK_URL"
		["em_app_support_email"]="EM_APP_SUPPORT_EMAIL"
	)	