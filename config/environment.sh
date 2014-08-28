#!/bin/bash

######################### BEGIN OF CONFIG #########################

# file storing the logs.
LOG_FILE=../logs/test-logs.log

# directory storing files of thes existent guests, like openrc, current user etc
GUESTS_DIR=../guests

# file with current existent users
GUESTS_FILE=$GUESTS_DIR/current-guests.list

# directory storing the credentials of the existent users
CREDENTIALS_DIR=$GUESTS_DIR/credentials

# script that sends the confirmation email
CONFIRMATION_MAIL=../config/mails/creation-mail.sh

########################## END OF CONFIG ##########################

# formated echo with green OK.
echo_status_ok() {
	echo -e "$1 ............. \e[32mOK"; tput sgr0
}

# formated echo with red FAIL.
echo_status_fail() {
	echo -e "$1 ............. \e[31mFAIL"; tput sgr0
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
	echo -e "\e[31m$1"  1>&2 ; tput sgr0
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
