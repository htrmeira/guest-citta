#!/bin/bash

# This script removes a guest user with his tenant, instances, volumes, snapshots, snapshots volumes, networks and routers.

######################### BEGIN OF CONFIG #########################

source ../config/environment.sh

#guest_username=guest046981
#guest_username=Silibrina

########################## END OF CONFIG ##########################

list_instance_ids() {
	nova list --all-tenants=1 --tenant=$tenant_id | grep -v "ID" | grep "^| " | awk '{print $2}'
}

# terminate all the instances of the current tenant.
# I the given user a guest it will
terminate_instances() {
	instance_ids=`list_instance_ids`
	success_or_die

	echo "==> Terminating instances..."
	for instance in $instance_ids; do
		echo -n "	Terminating $instance..."
		nova delete $instance
		check_status_quietly $?
	done
	local status=$?
	echo -n "==> Instances terminated"
	check_status_quietly $status
}

# This method lists the ids of all the images and snapshots of the tenant in use.
# The tenant id is defined in $tenant_id.
list_image_ids() {
	glance image-list --all-tenants --owner $tenant_id | grep -i "^| " | grep -v "ID" | awk '{ print $2 }'
}

# Removes the images and snapshots belonging to the tenant in use.
# The tentant id is defined in $tenant_id
delete_images() {
	image_ids=$(list_image_ids)
	echo "==> Deleting images and snapshots..."
	for image in $image_ids; do
		echo -n "	Deleting $image..."
		glance image-update --is-public=False --is-protected=False $image
		nova image-delete $image
		check_status_quietly $?
	done
	local status=$?
	echo -n "==> Images and snapshots deleted"
	check_status_quietly $status
}

list_volume_snapshot_ids() {
	local volume_snapshot_ids=$(cinder snapshot-list --all-tenants |  grep -i "^| " | grep -v "ID" | awk '{ print $2 }')
	for volume_snapshot in $volume_snapshot_ids; do
		local tenant=$(cinder snapshot-show $volume_snapshot | grep os-extended-snapshot-attributes:project_id | awk '{ print $4 }')
		if [ "$tenant" == "$tenant_id" ]; then
			echo $volume_snapshot
		fi
	done
}

delete_volume_snapshot_ids() {
	volume_snapshot_ids=$(list_volume_snapshot_ids)
	echo "==> Deleting volume snapshots..."
	for volume_snapshot in $volume_snapshot_ids; do
		echo -n "	Deleting $volume_snapshot..."
		cinder snapshot-delete $volume_snapshot
		check_status_quietly $?
	done
	local status=$?
	echo -n "==> Volume snapshots deleted"
	check_status_quietly $status
}

# This is the main of this script.
delete_guest() {
	terminate_instances
	delete_images
	delete_volume_snapshot_ids
}

check_username() {
	if [ -z $guest_username ]; then
		echo_fail "I am not a psychic! Give me a usename, please."
		exit 1;
	fi
}

check_tenant() {
	tenant_id=$(keystone tenant-list | grep $guest_username | awk '{ print $2 }')

	if [ -z $tenant_id ]; then
		echo_fail "Apparently, you are crazy and this user does not exist. Please check your parameters"
		exit 1;
	fi

}

define_parameters() {
	while [ ! -z $1 ]; do
		case $1 in
			-u | --username)
				shift
				guest_username=$1
				;;
		esac
		shift
	done
	check_username
	check_tenant
}


#delete_guest
#delete_images
#delete_volume_snapshot_ids

define_parameters $@
