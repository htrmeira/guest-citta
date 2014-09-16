#!/bin/bash

######################### CONFIG #########################

# TODO: check credentials
# TODO: log stdout and stderr.

source ../config/environment.sh

############# CHECKING PARAMETERS ##############

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
		echo_fail "Apparently, you are crazy and this user does not exist. Please check your parameters"
		exit 1;
	fi
}

# Define the arguments provided for this is script as variables and checks if it is all ok.
define_parameters() {
	while [ ! -z $1 ]; do
		case $1 in
			-u | --username)
				shift;
				guest_username=$1;
				;;
		esac
		shift
	done
	check_username;
	success_or_die;
}

######################### CLEAN UP #########################

cleanup_user() {
	./cleanup-guest.sh --username $guest_username
	success_or_die
}

###################### KEYSTONE ####################

delete_user() {
	echo -n "==> Deleting user $guest_username..."
	keystone user-delete $guest_username
	check_status_quietly $?
	echo "==> Done"
}

delete_tenant() {
	echo -n "==> Deleting tenant $guest_username..."
	keystone tenant-delete $guest_username
	check_status_quietly $?
	echo "==> Done"
}

delete_credentials() {
	local credentials_file=$CREDENTIALS_DIR/$guest_username-openrc.sh;
	echo "==> Removing credentials ($credentials_file)..."
	if [ ! -e $credentials_file ]; then
		echo_fail "The crendentials of this user does not exists.";
		exit 1;
	elif [ ! -s $credentials_file ]; then
		echo_fail "The file with the credentials seems to be empty. Please check it.";
		exit 1;
	fi
	rm $credentials_file
	echo "==> Done"
}

delete_guest_status() {
	echo -n "==> Removing guest user from current users..."
	sed -i.bak "/^$guest_username \:/d" $GUESTS_FILE
	check_status_quietly $?
	echo "==> Done"
}

resurrect_tenant() {
	keystone tenant-update $guest_username --enabled=True
	success_or_die;
}

################## EMAIL ##############

send_notification() {
	local guest_email=$(keystone user-list | grep -i "| *$guest_username *|" | awk -F\| '{ print $5 }' | tr -d ' ')
	success_or_die;
	$DELETIONION_MAIL --username $guest_username --email $guest_email
}

################ MAIN #################
main() {
	define_parameters $@;
	success_or_die;

	resurrect_tenant;
	success_or_die;

	cleanup_user;

	send_notification;

	delete_user;
	delete_tenant;
	delete_credentials;
	delete_guest_status;
}

main $@;
