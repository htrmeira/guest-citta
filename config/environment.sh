#!/bin/bash

######################### BEGIN OF CONFIG #########################

# The parent directory where the script is installed.
PARENT_DIR=/home/heitor/workspace/guest-citta

# file storing the logs.
LOG_FILE=$PARENT_DIR/logs/creation-logs.log

# directory storing files of thes existent guests, like openrc, current user etc
GUESTS_DIR=$PARENT_DIR/guests

# file with current existent users
GUESTS_FILE=$GUESTS_DIR/current-guests.list

# directory storing the credentials of the existent users
CREDENTIALS_DIR=$GUESTS_DIR/credentials

# script that sends the confirmation email
CONFIRMATION_MAIL=$PARENT_DIR/config/mails/creation-mail.sh

# script that send the notification about account suspension.
SUSPENSION_MAIL=$PARENT_DIR/config/mails/suspension-mail.sh

# script that sends the notification about account deletion.
DELETIONION_MAIL=$PARENT_DIR/config/mails/deletion-mail.sh

########################## END OF CONFIG ##########################

# formated echo with green OK.
echo_status_ok() {
	if [ "$TERM" != "dumb" ];then
		echo -e "$1 ............. \e[32mOK"; tput sgr0
	else
		echo -e "$1 ............. OK"
	fi
}

# formated echo with red FAIL.
echo_status_fail() {
	if [ "$TERM" != "dumb" ];then
		echo -e "$1 ............. \e[31mFAIL"; tput sgr0
	else
		echo -e "$1 ............. FAIL"
	fi
}

# checks if a given status is ok or not.
# if not, notify the erro and exit the script with error number 1.
check_status() {
	if [ "$1" -ne "0" ]; then
		echo_status_fail ""
		echo_fail "An error occurred, please check the logs"
		exit 1;
	fi
}

success_or_die() {
	if [ "$?" -ne "0" ]; then
		echo_fail "An error occurred, please check the logs"
		exit 1;
	fi
}

check_status_quietly() {
	if [ "$1" -ne "0" ]; then
		echo_status_fail $2
	else
		echo_status_ok $2
	fi
}

echo_fail() {
	if [ "$TERM" != "dumb" ];then
		echo -e "\e[31m$1"  1>&2 ; tput sgr0
	else
		echo -e "$1"  1>&2
	fi
}

# verify if the variables necessary to make a conection with the cloud are declared.
# note that this method does not verify if this user has permission to create a user.
verify_credetials() {
	if [ -z $OS_AUTH_URL ] || [ -z $OS_TENANT_ID ] || \
	[ -z $OS_TENANT_NAME ] || [ -z $OS_USERNAME ]; then
		echo_fail "You must define your credentials first."
		exit 1;
	fi
}

# This method checks if a user was provided as argument of this script.
# If not it will exit with error.
check_username() {
	if [ -z $guest_username ]; then
		echo_fail "I am not a psychic! Give me a usename, please."
		exit 1;
	fi
}

# Checks if the user provided has a tenant.
# This is also a way to check if the user provided exists on server.
check_tenant() {
	tenant_id=$(keystone tenant-list | grep $guest_username | awk '{ print $2 }')

	if [ -z $tenant_id ]; then
		echo_fail "Apparently, you are crazy and this user does not exists. Please check your parameters"
		exit 1;
	fi
}
