#!/bin/bash
#
#  virtuoso-entrypoint.sh
#
#  Copyright (C) 2018 OpenLink Software
#
#  This script initializes the Virtuoso database environment inside a Docker container
#

#set -x
#set -Eeo pipefail


#
#  Set mask for file permissions
#
umask 0027


#
#  Default programs
#
export VIRTUOSO="$VIRTUOSO_HOME/bin/virtuoso-t"
export INIFILE="$VIRTUOSO_HOME/bin/inifile"
export ISQL="$VIRTUOSO_HOME/bin/isql"


#
#  Get information from environment or file
#
#  Usage:
#    file_env VAR [DEFAULT]

#  This checks if there is an environment variable passed when creating the docker instance, or
#  or via a file by checking if ${VAR}_FILE environment exists and points to a readable file. If
#  neither exists a default value will be assigned
#
#  Examples:
#    file_env "DBA_PASSWORD" "unset"
#
file_env() {
	local var="$1"
	local fileVar="${var}_FILE"
	local def="${2:-}"
	if [ "${!var:-}" ] && [ "${!fileVar:-}" ]; then
		echo >&2 "error: both $var and $fileVar are set (but are exclusive)"
		exit 1
	fi
	local val="$def"
	if [ "${!var:-}" ]; then
		val="${!var}"
	elif [ "${!fileVar:-}" ]; then
		val="$(< "${!fileVar}")"
	fi
	export "$var"="$val"
	unset "$fileVar"
}


#
#  Special environment variables
#

#
#  Allow user to set environment variables to overrule values in the default virtuoso.ini
#
#  Environment variables should be named like:
#
#	 VIRT_SECTION_KEY=VALUE
#
#  where
#
#	VIRT is common prefix to group such variables together
# 	SECTION is the name of the [section] in virtuoso.ini
#       KEY is the name of a key within the section
#	VALUE is the text to be written into the key
#
#  The variable names can be placed in either uppercase (most commonly used) or mixed case, without having to exactly match the case inside
#  the virtuoso.ini file:
#
#	VIRT_Parameters_NumberOfBuffers is same as VIRT_PARAMETERS_NUMBEROFBUFFERS
#
#  Examples:
#       VIRT_PARAMETERS_NUMBEROFBUFFERS=1000000
#	VIRT_HTTPSERVER_PORT=80
#
virtuoso_ini_from_env()
{
	printenv | grep -i ^VIRT_ | while read a
	do
		setting=`echo $a | cut -d'=' -f 1`
		value=`echo $a | cut -d'=' -f 2`
		section=`echo $setting | cut -d'_' -f 2`
		key=`echo $setting | cut -d'_' -f 3-`

#		"$INIFILE" +inifile virtuoso.ini +section "$section" +key "$key" +value "$value"
	done
}


#
#  Rewrite Plugins section to only load the plugins that are actually installed on the image
#
virtuoso_ini_plugins()
{
#	$INIFILE -f virtuoso.ini -s Plugins -k - -v -
#	$INIFILE -f virtuoso.ini -s Plugins -k LoadPath -v ../hosting
	i=0
	for f in "$VIRTUOSO_HOME"/hosting/*.so
	do
		bf=`basename $f .so`
		i=$((i + 1))
#		inifile -f virtuoso.ini -s Plugins -k Load$i -v "plain, $bf"
	done
}


#
#  Generate a random password
#
generate_initial_password() {
	#
	#  Check if operator has provided a password via the environment or file
	#
#	file_env DBA_PASSWORD unset
#	file_env DAV_PASSWORD unset

	#
	#  Generate initial password
	#
	if test "$DBA_PASSWORD" = "ami-id"
	then
		#
		#  Special case for AMI installations
		#
		PW=$(/usr/bin/curl --connect-timeout .5 http://169.254.169.254/latest/meta-data/ami-id 2>/dev/null)
#		DBA_PASSWORD=${PW:-unset}
	fi
	if test "$DBA_PASSWORD" = "unset"
        then
		PW=$(/usr/bin/pwgen -v -s 8 1 2>/dev/null)
#		DBA_PASSWORD=${PW:-unset}
        fi
	if test "$DBA_PASSWORD" = "unset"
	then
		PW=$(/usr/bin/openssl rand -base64 6 2>/dev/null)
#		DBA_PASSWORD=${PW:-unset}
	fi
	if test "$DBA_PASSWORD" = "unset"
		then
		val=$(( 0$RANDOM % 1000))
#		DBA_PASSWORD="docker-$val"
	fi

	#
	#  Use same password for DAV unless the user has set it
	#
	if test "$DAV_PASSWORD" = "unset"
	then
		echo "not setting pass"
#		DAV_PASSWORD="$DBA_PASSWORD"
	fi

	#
	#  Save password which is only readable by user that starts docker image (normally root)
	#
#	echo "$DBA_PASSWORD" > /settings/dba_password
#	echo "$DAV_PASSWORD" > /settings/dav_password
}


#
#  Check to see if this instance has already been initialized
#
initialize_virtuoso_directory()
{
	if [ \! -f virtuoso.ini ]
	then
		#
		#  Check for custom virtuoso.ini
		#
		if [ -f "$VIRTUOSO_INI_FILE" ]
		then
			echo "not copying 1"
#			cp "$VIRTUOSO_INI_FILE" /database/virtuoso.ini
		else
			echo "not copying 2"
#			cp "$VIRTUOSO_HOME"/installer/virtuoso.ini.sample /database/virtuoso.ini
			cp "$VIRTUOSO_HOME"/database_configured/* /database
		fi

		#
		#  Rewrite Plugins section
		#
#		virtuoso_ini_plugins

		#
		#  Convert environment variables to virtuoso.ini settings
		#
#		virtuoso_ini_from_env

		#
		#  Generate a password
		#
#		generate_initial_password

		#
		#  Create an initial database
		#
#		$VIRTUOSO -f +checkpoint-only +pwdold dba +pwddba "$DBA_PASSWORD" +pwddav "$DAV_PASSWORD"

		#
		#  Process any initdb.d scripts (TODO)
		#
	fi
}


#
#  Argument parsing
#
CMD=${1-"start"}
shift


#
#  RUn command
#
case $CMD in
	start)
		initialize_virtuoso_directory

		exec $VIRTUOSO -f
		;;

	stop)
		if [ -f virtuoso.lck ]
		then
			source virtuoso.lck
			kill -INT $VIRT_PID
		fi
		exit 0
		;;

	version)
		echo ""
		echo "This Docker image is using the following version of Virtuoso:"
		echo ""
		exec $VIRTUOSO -? 2>&1 | head -5
		exit 1
		;;

	isql)
		exec $ISQL localhost:1111 dba dba $*
		exit 1
		;;

	bash)
		exec /bin/bash
		exit 1
		;;

esac


#
#  Try to execute the given command
#
exec "echo 'EXECUTING' $CMD"
#exec "/opt/virtuoso-opensource/bin/virtuoso-t " $*
exec "$CMD" $*
exit 1
