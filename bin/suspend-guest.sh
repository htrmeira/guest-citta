#!/bin/bash

######################### CONFIG #########################

source ../config/environment.sh

######################### NOVA ########################

list_instances() {
	nova list --all-tenants 1 --tenant $tenant_id | grep -i "^|" | grep -v "^| *ID *|" | awk '{ print $2 }'
}

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

suspend_tenant() {
	echo "==> Suspending tenant..."
	keystone tenant-update $guest_username --enabled=disable
	check_status
	echo "==> Done"
}

send_notification() {
	local guest_email=$(keystone user-list | grep -i "| *$guest_username *|" | awk -F\| '{ print $5 }' | tr -d ' ')
	$SUSPENSION_MAIL --username $guest_username --email $guest_email
}

############# CHECKING PARAMETERS ##############

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

	check_tenant;
	success_or_die;
}

main() {
	verify_credetials;
	success_or_die;

	define_parameters $@;

	suspend_instances;
	suspend_tenant;

	send_notification;
}

main $@;
