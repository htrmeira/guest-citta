#!/bin/bash

# This script suspends a guest user.
# It will suspend all instances of the user-tenant and disabled the tenant.
# param $1:
#   -u | --username: the username of the guest (MANDATORY)
#   -h | --help: shows this help

######################### CONFIG #########################

# The parent directory where the script is installed.
PARENT_DIR=/home/heitor/workspace/guest-citta

# The bin dir inside the parent dir.
# This is the directory that stores the main scripts including this one.
BIN_DIR=$PARENT_DIR/bin

source $PARENT_DIR/config/environment.sh

######################### NOVA ########################

# Lists ids of all instances of the given user-tenant.
list_instances() {
	nova list --all-tenants 1 --tenant $tenant_id | grep -i "^|" | grep -v "^| *ID *|" | awk '{ print $2 }'
}

# Suspends all instances of the given user-tenant.
suspend_instances() {
	echo "==> Suspending instances..."
	local instance_ids=$(list_instances)
	for instance_id in $instance_ids; do
		echo -n "   Suspending $instance_id..."
		nova suspend $instance_id
		check_status_quietly $?
	done
	echo "==> Done"
}

################### KEYSTONE ###################

# Disable the tenant.
suspend_tenant() {
	echo "==> Suspending tenant..."
	keystone tenant-update $guest_username --enabled=disable
	check_status $?
	echo "==> Done"
}

# Sends an email notifying the user that his account is being suspended.
send_notification() {
	local guest_email=$(keystone user-list | grep -i "| *$guest_username *|" | awk -F\| '{ print $5 }' | tr -d ' ')
	$SUSPENSION_MAIL --username $guest_username --email $guest_email
}

################# LOCAL ####################

# Updates the users status on $GUEST_FILE.
# It will change it from 0 to 1.
update_status() {
	echo -n "==> Updating user status..."
	sed  -i.bak "/^$usuario/{ s/: 0$/: 1/ }" $GUESTS_FILE
	check_status_quietly $?
	echo "==> Done"
}

############# CHECKING PARAMETERS ##############

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

	check_tenant;
	success_or_die;
}

main() {
	verify_credetials;
	success_or_die;

	define_parameters $@;

	suspend_instances;
	suspend_tenant;
	update_status;

	send_notification;
}

main $@;
