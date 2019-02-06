#!/bin/bash
##=====================================================================================================================
##COMMON_CONSTANT
##=====================================================================================================================

readonly FLAG_ENABLE=1
readonly FLAG_DISABLE=0

readonly EXEC_RULE_ABORT=1
readonly EXEC_RULE_WARN=2

readonly CODE_EXEC_SUCCESS=0
readonly CODE_PARSE_ERROR=1
readonly CODE_INPUT_ERROR=2
readonly CODE_IO_FAILURE=3
readonly CODE_EXEC_ERROR=4
readonly CODE_EXEC_WARN=5
readonly CODE_OPENSSL_ERROR=6
readonly CODE_CONCURRENCY_ERROR=7
readonly CODE_CONFIG_ERROR=8
readonly CODE_OS_ERROR=9
readonly CODE_DEPS_ERROR=10

#=====================================================================================================================
#LOGGING_CONSTANT
#=====================================================================================================================

readonly CODE_ERROR='\033[0;31m' #RED_COLOR
readonly CODE_OK='\033[0;32m'  #GREEN_COLOR
readonly CODE_WARNING='\033[0;33m' #BROWN/ORANGE_COLOR   
readonly CODE_NC='\033[0m' #NO_COLOR`


declare -a LOG_PREFIX=("${CODE_OK}INFO:" "${CODE_ERROR}ERROR:" "${CODE_WARNING}WARN:"  "${CODE_OK}DEBUG:")
declare -a LOG_SUFFIX=(" successful${CODE_NC}" " failed!${CODE_NC}" " not successful !${CODE_NC}"  ".${CODE_NC}")

readonly LOG_OK=0
readonly LOG_ERROR=1
readonly LOG_WARN=2
readonly LOG_DEBUG=3

#DEFAULT_LOGGING
declare FLAG_VERBOSE=$FLAG_DISABLE
declare LOG_FILE=""
#=====================================================================================================================
#VARIABLES
declare SELF_PID=$$
declare EXIT_STAT_FILE=$(mktemp)
declare LOG_PREFIX=""


to_stderr(){
	(>&2 $*)
}


log_msg()
{
	local log_level=$1
	local log_msg=$2
	#if [ $FLAG_VERBOSE -eq $FLAG_ENABLE ] || [ $log_level -eq $LOG_ERROR ]; then
	if [ $FLAG_VERBOSE -eq $FLAG_ENABLE ]; then
		to_stderr echo -e "${LOG_PREFIX[$log_level]} ${log_msg} ${LOG_SUFFIX[$log_level]}"
		if [ ! -z "$LOG_FILE" ] && [ -f $LOG_FILE ]; then
			echo -e "${LOGGING_PREFIX} [$(date +'%Y-%m-%d %H:%M:%S')]\$ ${LOG_PREFIX[$log_level]} ${log_msg} ${LOG_SUFFIX[$log_level]}" >> "$LOG_FILE"
			#echo -e "$LOG_FILE"
		fi
	fi
}
get_log()
{
	echo $FLAG_VERBOSE
}

set_log()
{
	FLAG_VERBOSE=$1
	LOGGING_PREFIX=$2
}
set_log_file()
{
	if [ ! -z "$1" -a "$1" != " " ]; then
	    LOG_FILE=$1
		touch $LOG_FILE
		chmod 755 $LOG_FILE
		log_msg $LOG_DEBUG "LOG_FILE:$LOG_FILE"
	fi
}

send_status()
{
  #log_msg $LOG_DEBUG "Caught Signal ..."
  local exit_val=$(cat $EXIT_STAT_FILE)
  rm -rf $EXIT_STAT_FILE
  exit $exit_val
}

exit_script()
{
	local log_level=$1
	local log_msg="$2"
	local exit_code=$3
	log_msg $log_level "$log_msg"
	#if [[ $exit_code != $CODE_CONCURRENCY_ERROR ]]; then
		#sleep 30
	#fi
	if [ $log_level -eq $LOG_ERROR ] || [ $log_level -eq $LOG_WARN ]; then
		$(echo $exit_code > $EXIT_STAT_FILE )
		$(kill -2 $SELF_PID)
	elif [[ $1 -eq $LOG_OK ]]; then
		exit $CODE_EXEC_SUCCESS
	fi
}

get_last_cmd_exec_status()
{
	local last_exec_stat=$?
	return $last_exec_stat
}

exec_linux_cmd()
{
	local exec_cmd="$1"
	local exec_rule=$2
	local log_msg="$3"
	local exit_code=$4

	eval "$exec_cmd"
	last_exec_stat=$?

	if [ $last_exec_stat -ne 0 ] && [ $exec_rule -eq $EXEC_RULE_ABORT ]; then
		exit_script $LOG_ERROR "$log_msg" $exit_code
	elif [ $last_exec_stat -ne 0 ] && [ $exec_rule -eq $EXEC_RULE_WARN ]; then
		log_msg $LOG_WARN "$log_msg"
	else
		log_msg $LOG_DEBUG "$LOG_MSG : CMD:$exec_cmd"
	fi
}

lock() {
	local lock_fd=$1
	local file_name=$2

	eval "exec $lock_fd>/var/lock/.${file_name}_lock"
    flock -n $lock_fd \
        && return 0 \
        || return 1
}

update_agent_config()
{
	local cs_ip=$1
	local token=$2
	local agent_conf=$3
	sed -i "s/\(server\=\"\)\(.*\)\(\"\)/\1$cs_ip\3/g" $agent_conf
	sed -i "s/\(token\=\"\)\(.*\)\(\"\)/\1$token\3/g" $agent_conf
}

check_proxy()
{
	if [[ (-z "${http_proxy}")||(-z "${https_proxy}") ]];
	then
		log_msg $LOG_ERROR "HTTP Proxies not set. If you are running this installer behind a proxy, please set up http_proxy and https_proxy environment variables before installation."
		return $CODE_CONFIG_ERROR
	else
		log_msg $LOG_DEBUG "HTTP Proxies for http and https set. Continuing installation....."
		return $CODE_EXEC_SUCCESS
	fi
}


check_linux_version() {
	OS=$(cat /etc/*release | grep ^NAME | cut -d'"' -f2)
	VER=$(cat /etc/*release | grep ^VERSION_ID | tr -d 'VERSION_ID="')

	PARAM_OS=$1
	PARAM_VER=$2
	

    if [ "$OS" == "$PARAM_OS" ]
    then
		if [ ${VER} != "$PARAM_VER" ] 
		then
			log_msg $LOG_ERROR "Error: OS distribution ${OS} version ${VER} NOT Correct!\n"
			return $CODE_OS_ERROR
		fi
    else
        log_msg $LOG_ERROR "Error: OS distribution ${OS}:${PARAM_OS} Not Supported\n"
        return $CODE_OS_ERROR
    fi
	return $CODE_EXEC_SUCCESS
} 
CheckWhetherProcessRunning()
{
	local process_name="$1"
	if pgrep -x "$process_name" > /dev/null
	then
		return $CODE_EXEC_SUCCESS
	else
		return $CODE_EXEC_ERROR
	fi
}


download_deps()
{
	pushd "$PWD"
	cd "$1"
	$(exec_linux_cmd "git submodule init" $EXEC_RULE_ABORT "Git Submodule init command" $CODE_EXEC_SUCCESS)
	$(exec_linux_cmd "git submodule update" $EXEC_RULE_ABORT "Git Submodule update command" $CODE_EXEC_SUCCESS)
	popd 
}



check_pre_condition()
{
    PROXY_REQUIRED=$1

    if [ $PROXY_REQUIRED -eq $FLAG_ENABLE ]; then
        $(check_proxy)
        if [ $? -ne $CODE_EXEC_SUCCESS ]; then
            log_msg $LOG_ERROR "Proxy"
            return $CODE_EXEC_ERROR
        fi
    fi

    $(check_linux_version "${DHSM2_COMPONENT_INSTALL_OS}" "${DHSM2_COMPONENT_INSTALL_OS_VER}")
    if [ $? -ne $CODE_EXEC_SUCCESS ]; then
        log_msg $LOG_ERROR "Invalid Enviromnent"
        return $CODE_EXEC_ERROR
    fi
}



install_pre_requisites()
{
	local PRE_REQUISITES="none"

	if [ -z "$1" ]; then
		PRE_REQUISITES="all"
	else
		PRE_REQUISITES="$1"
	fi

	if [ $PROXY_REQUIRED -eq $TRUE ]; then 
		check_proxy
		if [ $? -ne 0 ]; then 
			exit_script $LOG_ERROR "Invalid Proxy" $CODE_EXEC_ERROR
		fi
	fi

	if [ "${PRE_REQUISITES}" = "dev" ]; then
	   $DHSM2_COMPONENT_OS_PAC_INSTALLER update -y && $DHSM2_COMPONENT_OS_PAC_INSTALLER install ${DHSM2_COMPONENT_DEV_PRE_REQUISITES} -y
	elif  [ "${PRE_REQUISITES}" = "devOps" ]; then 
	   $DHSM2_COMPONENT_OS_PAC_INSTALLER update -y && $DHSM2_COMPONENT_OS_PAC_INSTALLER install ${DHSM2_COMPONENT_DEVOPS_PRE_REQUISITES} -y
	elif [ "${PRE_REQUISITES}" = "all" ]; then
	   $DHSM2_COMPONENT_OS_PAC_INSTALLER update -y && $DHSM2_COMPONENT_OS_PAC_INSTALLER install $DHSM2_COMPONENT_DEVOPS_PRE_REQUISITES -y && $DHSM2_COMPONENT_OS_PAC_INSTALLER install ${DHSM2_COMPONENT_DEV_PRE_REQUISITES} -y
	fi

	if [ $? -ne 0 ]; then
		exit_script $LOG_ERROR "Pre-Requisites installation" $CODE_EXEC_ERROR
	fi
	log_msg $LOG_DEBUG "Pre-Requisites installation" 

}

set_permission_and_grp()
{
	groupadd ${DHSM2_COMPONENT_GRP}
	if [ $? -eq 0 ] || [ $? -eq 9 ]; then
		exit_script $LOG_ERROR "Group ${DHSM2_COMPONENT_GRP} add" $CODE_EXEC_ERROR
	fi 

	if [ ! -d ${DHSM2_COMPONENT_INSTALL_DIR} ]; then
		exit_script $LOG_ERROR "Group ${DHSM2_COMPONENT_GRP} add configuration failed" $CODE_EXEC_ERROR
	fi
	chgrp -hR ${DHSM2_COMPONENT_GRP} ${DHSM2_COMPONENT_INSTALL_DIR} 
	chmod ${DHSM2_COMPONENT_GRP_PERMISSION} ${DHSM2_COMPONENT_INSTALL_DIR}
	chmod +t ${DHSM2_COMPONENT_INSTALL_DIR}
}
