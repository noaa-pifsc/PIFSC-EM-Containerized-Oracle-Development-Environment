#!/bin/bash

# function that processes user runtime arguments and executes the specified script action (deploy or shutdown)
# This function accepts the following parameters as elements in the specified array name (arg_array): 
# script_action: (optional) passed script_action value (deploy, shutdown)
# env_name: (optional) environment name (dev, test)
# deploy_dest: (optional) deploy destination (local, server)
# rem_vol: (optional) remove volume flag: remove the volumes associated with the docker stack name (yes) or retain them (no). The default value is "no"
# build_path: the full path to the directory where the docker source files are located
# ords_enabled: flag to indicate if the ords container is enabled
# compose_project_name: the project name used to prefix the names of container objects to ensure uniqueness
# db_host_port: The docker host's container port mapped to the database container for connectivity
# ords_host_port: The docker host's container port mapped to the ords container for web requests
# db_image: The container database image used in the given CODE project
# ords_image: The container ORDS image used in the given CODE project
# target_apex_version: The target Apex version that will be installed/upgraded to on the ORDS container
# app_schema_name: primary schema created by deployment script, used to check if the database is installed
# dbport: The internal container database port
# dbhost: The internal container database name
# dbservicename: The internal container database service name
# stack_name: The container stack name
# network_name: The container network name
# secret_mapping_var_name: the name of the configuration data variable that is passed via STDIN that contains secret values
# priv_user: The privileged host server user name that can execute container procedures
# hostname: container server hostname 
# host_source_path: container server CODE source path 
# git_url: the container git repository URL
# host_scripts_path: container server CODE source folder's host scripts path
# secret_data_var_name: variable to store the name of the configuration data variable that is passed via STDIN that contains secret values
# compose_file_array: name of an array that stores the compose files for each individual CODE project
# project_linear_dependencies_var: array variable name
# projects_path: is the absolute path to the /projects folder in the root repository directory
function code_client_process_arguments_execute_container_scripts ()
{
	# store the function array argument
	local arg_array="${1}"

    # Validation check: ensure the argument is a valid array
    if [[ "$(declare -p "${arg_array}" 2>/dev/null)" != "declare -A"* ]]; then
        echo "Error: ${FUNCNAME[0]}() function argument '${arg_array}' is not a valid associative array." >&2
        return 1
    fi

	# input validation:
	if ! cds_shared_validate_required_array_vals "${arg_array}" "ords_enabled" "build_path" "secret_mapping_var_name" "compose_project_name" "db_host_port" "ords_host_port" "db_image" "ords_image" "app_schema_name" "dbport" "dbhost" "dbservicename" "stack_name" "network_name" "config_dir" "hostname" "host_source_path" "git_url" "host_scripts_path" "secret_data_var_name" "compose_file_array" "project_linear_dependencies_var" "projects_path"; then
        echo "Error: ${FUNCNAME[0]}() function argument validation failed" >&2
        return 1
    fi

	# create a pointer to the arg_array variable to make it easy to access the argument array values
	local -n arg_ref="${arg_array}"

	local script_action_name="script_action"
	local env_var_name="env_name"
	local dest_var_name="deploy_dest"
	local rem_vol_var_name="rem_vol"
	local passed_script_action="${arg_ref[script_action]:-}"
	local passed_env_value="${arg_ref[env_name]:-}"
	local passed_deploy_value="${arg_ref[deploy_dest]:-}"
	local passed_rem_vol_value="${arg_ref[rem_vol]:-no}"
	
	# validate the bash variable values
	if ! cds_shared_validate_required_vars	"script_action_name" "env_var_name" "dest_var_name"; then
		echo "Error: ${FUNCNAME[0]}() function required function argument validation failed" >&2
		return 1
	fi

	# save/prompt for script action type into the specified local variable
	cds_client_set_script_action_var "${script_action_name}" "${passed_script_action}"

	# save/prompt for environment name into the specified local variable
	cds_client_set_env_name_var "${env_var_name}" "${passed_env_value}" 

	# save/prompt for deployment destination (local, server) for Dual-Target capability
	cds_client_set_deploy_dest_var "${dest_var_name}" "${passed_deploy_value}"

	# save/prompt for remove volume flag (yes, no)
	cds_client_set_rem_vol_var "${rem_vol_var_name}" "${passed_rem_vol_value}"

	# notify the user of the user-defined runtime value
	echo ""
	echo "*****************************************"
	echo "Runtime Argument Values:"
	echo "script_action: ${!script_action_name}"
	echo "env_name: ${!env_var_name}"
	echo "deploy_dest: ${!dest_var_name}"
	echo "rem_vol: ${!rem_vol_var_name}"
	echo "*****************************************"
	echo ""
	
	# update the arg_ref array with the processed user-defined runtime values
	arg_ref[script_action]="${!script_action_name}"
	arg_ref[env_name]="${!env_var_name}"
	arg_ref[deploy_dest]="${!dest_var_name}"
	arg_ref[rem_vol]="${!rem_vol_var_name}"

	
#	echo "DEBUG: the code_client_execute_container_scripts() function arguments are: $(cds_shared_dump_array_vals "${arg_array}")"

	# execute the specified script action on the CODE containers 
	code_client_execute_container_scripts "${arg_array}"

	# notify the user that the script action has finished executing
	echo "The ${!script_action_name} action was successfully executed on the docker container(s) - environment name: ${!env_var_name}, deployment destination: ${!dest_var_name}, remove volume: ${!rem_vol_var_name}"
}

# the function returns the compose separator character based on the container deployment environment
# the function accepts the following parameters:
# 1: separator variable name: the name of the variable that defines the compose separator for multiple .yml files
# 2: deploy_dest: local or server, which determines the separator character
function code_client_get_compose_separator()
{
	local compose_sep_name="${1}"
	local deploy_dest="${2}"

	# validate the bash variable values
	if ! cds_shared_validate_required_vars "compose_sep_name" "deploy_dest"; then
        echo "Error: ${FUNCNAME[0]}() function required bash variable validation failed" >&2
        return 1
	fi

	# define the reference to the local variable
	local -n compose_sep_ref="${compose_sep_name}"

	# Determine the correct OS path separator for the COMPOSE_FILE environment variable for linux server deployments and for local Mac/Linux deployments
	compose_sep_ref=":"

	# check if the deployment destination is local
	if [[ "${deploy_dest}" == "local" ]]; then	
		# this is a local deployment, check if this is a windows machine
		case "$(uname -s)" in
			MINGW*|CYGWIN*|MSYS*)
				# this is a windows machine for a local deployment, use the semicolon separator
				compose_sep_ref=";"
				;;
		esac
	fi
}

# function that executes the specified script action on the CODE containers
# This function accepts the following parameters as elements in the specified array name (arg_array): 
# script_action: passed script_action value (deploy, shutdown)
# env_name: environment name (dev, test)
# deploy_dest: deploy destination (local, server)
# rem_vol: remove volume flag: remove the volumes associated with the docker stack name (yes) or retain them (no)
# build_path: the full path to the directory where the docker source files are located
# ords_enabled: flag to indicate if the ords container is enabled
# compose_project_name: the project name used to prefix the names of container objects to ensure uniqueness
# db_host_port: The docker host's container port mapped to the database container for connectivity
# ords_host_port: The docker host's container port mapped to the ords container for web requests
# db_image: The container database image used in the given CODE project
# ords_image: The container ORDS image used in the given CODE project
# target_apex_version: The target Apex version that will be installed/upgraded to on the ORDS container
# app_schema_name: primary schema created by deployment script, used to check if the database is installed
# dbport: The internal container database port
# dbhost: The internal container database name
# dbservicename: The internal container database service name
# stack_name: The container stack name
# network_name: The container network name
# secret_mapping_var_name: the name of the configuration data variable that is passed via STDIN that contains secret values
# priv_user: The privileged host server user name that can execute container procedures
# hostname: container server hostname 
# host_source_path: container server CODE source path 
# git_url: the container git repository URL
# host_scripts_path: container server CODE source folder's host scripts path
# secret_data_var_name: variable to store the name of the configuration data variable that is passed via STDIN that contains secret values
# compose_file_array: name of an array that stores the compose files for each individual CODE project
# project_linear_dependencies_var: array variable name
# projects_path: is the absolute path to the /projects folder in the root repository directory
function code_client_execute_container_scripts ()
{
	# store the function array argument
	local arg_array="${1}"

    # Validation check: ensure the argument is a valid array
    if [[ "$(declare -p "${arg_array}" 2>/dev/null)" != "declare -A"* ]]; then
        echo "Error: ${FUNCNAME[0]}() function argument '${arg_array}' is not a valid associative array." >&2
        return 1
    fi

	# input validation:
	if ! cds_shared_validate_required_array_vals "${arg_array}" "script_action" "env_name" "deploy_dest" "rem_vol" "ords_enabled" "build_path" "secret_mapping_var_name" "compose_file_array" "project_linear_dependencies_var" "projects_path"; then
        echo "Error: ${FUNCNAME[0]}() function argument validation failed" >&2
        return 1
    fi

	# create a pointer to the arg_array variable to make it easy to access the argument array values
	local -n arg_ref="${arg_array}"

	# declare variable to store the list of included .yml files when docker compose runs
	local compose_file

	# a pointer to the compose_file_array array variable
	local -n compose_file_array_ref="${arg_ref[compose_file_array]}"

	# construct the COMPOSE_FILE value of included .yml files, specify the COMPOSE_FILES elements for any additional .yml configuration files
	code_client_construct_compose_file_string "compose_file" "${arg_ref[env_name]}" "${arg_ref[deploy_dest]}" "${arg_ref[ords_enabled]}" "${compose_file_array_ref[@]}"
	
	# check if this is a deployment, if so load the local secret file so the container secret(s) can be created
	if [[ "${arg_ref[script_action]}" == "deploy" ]]; then
		echo "This is a deployment, attempt to load the secrets.sh file"

		# Check if the secret file exists:
		if [ -f "${arg_ref[build_path]}/../../secrets/secrets.sh" ]; then
			# load the secrets
			source "${arg_ref[build_path]}"/../../secrets/secrets.sh
		else
			echo "secrets.sh does not exist, check environment for the secret variables" >&2
		fi
		
		# check for the required secret variables to determine if they are undefined or empty
		local -n secret_map_ref="${arg_ref[secret_mapping_var_name]}"
		
		echo "check if the secret variables are defined" >&2
		
		if ! cds_shared_validate_required_vars "${secret_map_ref[@]}"; then
			echo "Error: ${FUNCNAME[0]}() - Required environment variables mapped in 'SECRET_MAPPING_ARR' are not defined." >&2
			return 1
		fi
	fi
	
	# check if this is a local or server deployment:
	if [[ "${arg_ref[deploy_dest]}" == "local" ]]; then
		# this is a local deployment

		# input validation:
		if ! cds_shared_validate_required_array_vals "${arg_array}" "compose_project_name" "db_host_port" "ords_host_port" "db_image" "ords_image" "app_schema_name" "dbport" "dbhost" "dbservicename" "stack_name" "network_name"; then
			echo "Error: ${FUNCNAME[0]}() function argument validation failed" >&2
			return 1
		fi

		# execute any pre-client hooks
		code_shared_run_project_hooks "pre" "client_local" "${arg_ref[project_linear_dependencies_var]}" "${arg_ref[projects_path]}"

		# export the environment variables based on the list of fields
		cds_shared_export_array_keys "${arg_array}" "compose_project_name" "db_host_port" "ords_host_port" "db_image" "ords_image" "target_apex_version" "app_schema_name" "dbport" "dbhost" "dbservicename" "stack_name" "network_name" "ords_enabled"
		
		# export additional custom environment variables
		cds_shared_export_env_vars "${CUSTOM_ENV_VARS[@]}"

		# check the script_action value to determine if this is a deployment or shutdown script
		if [[ "${script_action}" == "deploy" ]]; then
			# this is a deployment

			# declare the function arguments
			local -A deploy_args=(
				["stack_name"]="${arg_ref[stack_name]}"
				["secret_map"]="${arg_ref[secret_mapping_var_name]}"
				["network_name"]="${arg_ref[network_name]}"
				["deploy_dest"]="${arg_ref[deploy_dest]}"
				["build_image"]="yes"
				["compose_path"]="${compose_file}"
				["build_path"]="${arg_ref[build_path]}" 
				["secret_name_prefix"]="${arg_ref[compose_project_name]}_"
				["rem_vol"]="${arg_ref[rem_vol]:-no}"
			)
			
			# generate and export a timestamp to uniquely identify this deployment, this environment variable is defined in the code-ords and code-db-ords-deploy containers
			export DEPLOY_ID="$(date +%s)"

			# deploy the containers locally:
			cds_shared_deploy_container_stack "deploy_args"
		else
			# this is a shutdown script

			# shutdown the CODE containers to the host server associated with the $STACK_NAME
			cds_shared_remove_container_stack "${arg_ref[stack_name]}" "${arg_ref[network_name]}" "${arg_ref[rem_vol]:-no}" "${arg_ref[build_path]}" "${compose_file}"
		fi
		
		# execute any post-client hooks
		code_shared_run_project_hooks "post" "client_local" "${arg_ref[project_linear_dependencies_var]}" "${arg_ref[projects_path]}"
		
	else
		# this is a server deployment
		
		# input validation:
		if ! cds_shared_validate_required_array_vals "${arg_array}" "hostname" "host_source_path" "git_url" "host_scripts_path" "secret_data_var_name"; then
			echo "Error: ${FUNCNAME[0]}() function argument validation failed for the server deployment" >&2
			return 1
		fi

		# add compose_file as an arg_array element so it can be used to generate the environment variable string
		arg_ref["compose_file"]="${compose_file}"
		
		# execute any pre-client/server deployment hooks
		code_shared_run_project_hooks "pre" "client_server" "${arg_ref[project_linear_dependencies_var]}" "${arg_ref[projects_path]}"

		# define the global variables so they can be exported
		local env_var_string="$(cds_shared_generate_ssh_env_vars_string_from_array_keys "${arg_array}" "compose_project_name" "db_host_port" "ords_host_port" "db_image" "ords_image" "target_apex_version" "app_schema_name" "priv_user" "compose_file" "stack_name" "network_name" "rem_vol" "script_action" "ords_enabled")"

		# add the CUSTOM_ENV_VARS environment variables to the $env_var_string if there are any elements in the array
		if (( ${#CUSTOM_ENV_VARS[@]} > 0 )); then
			# add the custom environment variables to the env_var_string variable
			env_var_string+=" $(cds_shared_generate_ssh_env_vars_string ${CUSTOM_ENV_VARS[@]})"
		fi

		# echo "DEBUG: The value of the env_var_string is: ${env_var_string}"

		# assign the value of the process_secrets variable based on the script action value
		if [[ "${script_action}" == "deploy" ]]; then
			local process_secrets="yes"
		else
			local process_secrets="no"
		fi

		# declare the function arguments
		local -A remote_deploy_args=(
				["target_host"]="${arg_ref[hostname]}"
				["source_path"]="${arg_ref[host_source_path]}"
				["git_url"]="${arg_ref[git_url]}"
				["ssh_cmd"]="${env_var_string} bash ${arg_ref[host_scripts_path]}/host_execute_CODE_scripts.sh"
				["secret_var"]="${arg_ref[secret_data_var_name]}"
				["secret_map"]="${arg_ref[secret_mapping_var_name]}"
				["process_secrets"]="${process_secrets}"
			)
			
		# deploy the containers to the remote server
		cds_client_execute_remote_deployment "remote_deploy_args"

		# execute any post-client/server deployment hooks
		code_shared_run_project_hooks "post" "client_server" "${arg_ref[project_linear_dependencies_var]}" "${arg_ref[projects_path]}"

	fi
}

# function to construct the compose file string for docker compose
# the function accepts the following arguments:
# 1: compose_file_var is the name of the compose file variable that will contain the formatted list of compose files
# 2: env_name: the environment name (dev, test, prod)
# 3: deploy_dest: deployment destination (local, server)
# 4: ords_enabled: flag to indicate if the ords container is enabled
# $@: (Remaining args) the list of compose paths that will be added to the compose_file_var variable 
function code_client_construct_compose_file_string ()
{
	local compose_file_var="${1}"
	local env_name="${2}"
	local deploy_dest="${3}"
	local ords_enabled="${4}"

	# save a reference to the $compose_file_var variable
	local -n out_compose_file_ref="${compose_file_var}"

	# validate the bash variable values
	if ! cds_shared_validate_required_vars "env_name" "deploy_dest" "compose_file_var" "ords_enabled"; then
        echo "Error: ${FUNCNAME[0]}() function required bash variable validation failed" >&2
        return 1
	fi

	# compose separator variable
	local compose_sep 

	# store the compose separator character so it can be used to construct the formatted compose file list
	code_client_get_compose_separator "compose_sep" "${deploy_dest}"
	
	# build the list of compose files using $compose_sep as the separator for the target deployment machine:
	# include the code-db and code-db-ords-deploy services, and custom docker compose to integrate additional services
	out_compose_file_ref="./CODE-db-deploy.yml"

	# check if this is intended for a dev environment (retain the database volume across container restarts) 
	if [ "${env_name}" == "dev" ]; then
		# add in the named volume for the code-db service
		out_compose_file_ref="${out_compose_file_ref}${compose_sep}./CODE-db-named-volume.yml"
	fi
	
	# check if the ORDS/Apex service is enabled
	if [ "${ords_enabled}" == "yes" ]; then
		# include the ORDS service
		out_compose_file_ref="${out_compose_file_ref}${compose_sep}./CODE-ords.yml"
	fi
	
	# shift the array to process the project-specific .yml files
	shift 4

	# loop through the remaining arguments to add the project-specific .yml files
    for key in "$@"; do
		# append the current compose file
		out_compose_file_ref="${out_compose_file_ref}${compose_sep}${key}"
    done	
}