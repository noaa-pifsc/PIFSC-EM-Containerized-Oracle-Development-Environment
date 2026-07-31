#!/bin/bash

	# define the array of compose files that are used by the individual projects (specify the path relative to the core/build directory
	COMPOSE_FILES+=("../../projects/EM/build/em_secrets.yml")
	
	# add the secrets
	SECRET_MAPPING_ARR+=(
		["em_db_username_secret"]="EM_DB_USER"
		["em_db_password_secret"]="EM_DB_PWD"
		["em_app_username_secret"]="EM_APP_USER"
		["em_app_password_secret"]="EM_APP_PWD"
	)
	
	