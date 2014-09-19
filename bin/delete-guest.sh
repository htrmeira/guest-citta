#!/bin/bash

# This script cleans up a user and delete him with his tenant.
# Note that we are considering the tenant with the same name as the guest username.
# It will also send an email to user notifying about the removal of his user.
# param $1:
#   -u | --username: the username of the guest (MANDATORY)
#   -h | --help: shows this help

######################### BEGIN CONFIG #########################

# The parent directory where the script is installed.
PARENT_DIR=/home/heitor/workspace/guest-citta

# The bin dir inside the parent dir.
# This is the directory that stores the main scripts including this one.
BIN_DIR=$PARENT_DIR/bin

source $PARENT_DIR/config/environment.sh

######################## CHECKING PARAMETERS ####################

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

show_help() {
	echo "Paramters inside [] are not mandatory"
	echo "Usage:  $0 -u | --username GUEST_USERNAME"
	echo -e "\t$0 -h | --help"
	echo
	echo "-u | --username: the username of the guest (MANDATORY)"
	echo "-h | --help: shows this help"
}

# Define the arguments provided for this is script as variables and checks if it is all ok.
define_parameters() {
	while [ ! -z $1 ]; do
		case $1 in
			-u | --username)
				shift;
				guest_username=$1;
				;;
			*)
				show_help;
				exit 0;
				;;
		esac
		shift
	done
	check_username;
	success_or_die;
}

######################### CLEAN UP #########################

cleanup_user() {
	$BIN_DIR/cleanup-guest.sh --username $guest_username
	success_or_die
}

######################## KEYSTONE #########################

# Deletes the user on keystone.
# This is the real deletion of user. After this, it will be no able not login.
delete_user() {
	echo -n "==> Deleting user $guest_username..."
	keystone user-delete $guest_username
	check_status_quietly $?
	echo "==> Done"
}

# Deletes the tenant with the same name as the guest username.
delete_tenant() {
	echo -n "==> Deleting tenant $guest_username..."
	keystone tenant-delete $guest_username
	check_status_quietly $?
	echo "==> Done"
}

######################### LOCAL #########################

# Deletes the credentials file of the guest user.
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

# Removes the entry for this user on $GUESTS_FILE
delete_guest_status() {
	echo -n "==> Removing guest user from current users..."
	sed -i.bak "/^$guest_username \:/d" $GUESTS_FILE
	check_status_quietly $?
	echo "==> Done"
}

# Sets the tenants to enabled.
# This is necessary because suspending a user is updating the tenant to disbled
# and when disabled, the credentials of the user could not be loaded for
# the cleanup fase.
resurrect_tenant() {
	keystone tenant-update $guest_username --enabled=True
	success_or_die;
}

################## EMAIL ##############

# Sends an email notifying the user about the deletion of his user on the cloud.
send_notification() {
	local guest_email=$(keystone user-list | grep -i "| *$guest_username *|" | awk -F\| '{ print $5 }' | tr -d ' ')
	success_or_die;
	$DELETIONION_MAIL --username $guest_username --email $guest_email
}

################ MAIN #################
main() {
	verify_credetials;
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
