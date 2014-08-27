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
CONFIRMATION_MAIL=./mails/creation-mail.sh

########################## END OF CONFIG ##########################

# formated echo with green OK.
echo_status_ok() {
	echo -e "$1 ............. \e[32mOK"; tput sgr0
}

# formated echo with red FAIL.
echo_status_fail() {
	echo -e "$1 ............. \e[31mFAIL"; tput sgr0
}

# print a message in RED color, used to report fatal errors.
echo_fail() {
	echo -e "\e[31m$1"; tput sgr0
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

# checks if the email param was given.
# this is the only mandatory parameter, so it will fail if this param is not given.
check_email() {
	if [ -z $guest_email ]; then
		echo_fail "You must define an email!"
		exit 1;
	fi
}

# check if the username param was provided, if not generate a username.
# the generated username starts with guestXXXXXX, where X is an integer between 0 and 9.
check_username() {
	if [ -z $guest_username ]; then
		local guest_username_sufix=$(< /dev/urandom tr -dc 0-9 | head -c6; echo)
		guest_username="guest$guest_username_sufix"
	fi
}

# checks if a password was given as argument, if not it will generate a password.
# the generated password will have 13 characters, that can be numbers and letters (capitalized or not) and _.
check_password() {
	if [ -z $guest_password ]; then
		guest_password=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c13; echo)
	fi
}

# checks if a role was given, if not use the convidado role.
check_role() {
	if [ -z $guest_role ]; then
		guest_role=$(keystone role-list | grep -i convidado | awk '{ print $2 }')
	fi
}

# This will iterate over the given parameters and configure the variables.
define_parameters() {
	while [ ! -z $1 ]; do
		case $1 in
			-u | --username)
				shift
				guest_username=$1
				;;
			-e | --email)
				shift
				guest_email=$1
				;;
			-p | --password)
				shift
				guest_password=$1
				;;
			-r | --role)
				shift
				guest_role=$1
				;;
		esac
		shift
	done
	check_username;
	check_email;
	check_password;
	check_role;
}

# store in the log file the content of variables in this script.
debug_variables() {
	echo "username=$guest_username" >> $LOG_FILE
	echo "email=$guest_email" >> $LOG_FILE
	echo "role=$guest_role" >> $LOG_FILE
}

# checks if a given status is ok or not.
# if not, notify the erro and exit the script with error number 1.
check_status() {
	if [ "$1" -ne "0" ]; then
		echo_status_fail ""
		echo "An error occurred, please check the logs"
		exit 1;
	fi
}

# creates the user and a tenant on the cloud, this user will be the only one in the created tenant.
create_user() {
	echo -n "Wait while the user is being created..."
	keystone user-create --name=$guest_username --pass=$guest_password --email=$guest_email >> $LOG_FILE
	check_status $?;
	sleep 3
	echo -n "..."
	keystone tenant-create --name=$guest_username --description="Projeto criado para o usuario $guest_username" >> $LOG_FILE
	check_status $?;
	sleep 3
	echo -n "..."
	keystone user-role-add --user=$guest_username --role=$guest_role --tenant=$guest_username >> $LOG_FILE
	check_status $?;
	sleep 3
	echo_status_ok ""
}

# creates a credential file, this file will be sent by email to the user and can be used to access the cloud.
create_credentials_file() {
	mkdir -p $CREDENTIALS_DIR
	guest_file=$CREDENTIALS_DIR/$guest_username-openrc.sh

	echo "export OS_USERNAME=$guest_username" > $guest_file
	echo "export OS_PASSWORD=$guest_password" >> $guest_file
	echo "export OS_EMAIL=$guest_email" >> $guest_file
	echo "export OS_TENANT_NAME=$guest_username" >> $guest_file
	echo "export OS_AUTH_URL=http://10.0.0.14:35357/v2.0" >> $guest_file
}

# register this user on the current existing guest file.
# this is needed to keep track of the existent guests, and to make the necessary validation of the expiration time.
register_for_expiration() {
	DATE_STAMP=$(date +"%s")
	echo "$guest_username : $guest_email : $DATE_STAMP : 0" >> $GUESTS_FILE
	echo "created_at=`date`" >> $LOG_FILE
	echo "date_stamp=$DATE_STAMP" >> $LOG_FILE
}

# sends the confirmation email with the credentials file attached.
send_confirmation_email() {
	$CONFIRMATION_MAIL --username $guest_username --email $guest_email --password $guest_password --credentials_file $guest_file >> $LOG_FILE
	check_status $?;
}

# execute the creation of the guest
run_creation() {
	echo "==================== CREATING USER =================" >> $LOG_FILE
	verify_credetials
	define_parameters $@
	create_user
	create_credentials_file
	register_for_expiration
	send_confirmation_email
	debug_variables
	echo "==================== END CREATION =================" >> $LOG_FILE
}

# shows a short help.
show_help() {
	echo "Paramters inside [] are not mandatory"
	echo "Usage: $0 create -e | --email user@email.com [-u | --username user_name] [-p | --password password] [-r | --role role]"
	echo "-e | --email: the email of the user (MANDATORY)"
	echo "-u | --username: the username, generated if not given"
	echo "-p | --password: the password, generated if not given"
	echo "-r | --role: the role, convidado if not given"
}

case $1 in
	create)
		run_creation $@;
		exit 0;
		;;
	*)
		show_help;
		exit 0;
		;;
esac
