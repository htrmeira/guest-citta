#!/bin/bash

# This script removes all the instances, volumes, snapshots, snapshots volumes,
# networks and routers, trove instances and backups, heat stacks and backups of a guest user.
# It will cleanup the tenanant of this user freeing the resource used by him
# making it ready to be deleted.
#
# Note that for all parameters asking for a tenant, it will provide one with the
# same name as guest username.
# param $1:
#	-u | --username: the username of the guest (MANDATORY)
#	-h | --help: shows this help

######################### BEGIN OF CONFIG #########################

# The parent directory where the script is installed.
PARENT_DIR=/home/heitor/workspace/guest-citta

# The bin dir inside the parent dir.
# This is the directory that stores the main scripts including this one.
BIN_DIR=$PARENT_DIR/bin

source $PARENT_DIR/config/environment.sh

########################## END CONFIG ##########################


#################### NOVA ####################

# Lists the ids of all instances of the given user.
# It will consider that you are running the scriptwith the credentials
# of the user being deleted.
list_instance_ids() {
	nova list | grep -i "^|" | grep -v "^| *ID *|" | awk '{ print $2 }'
}

# Terminate instances all instances of this guest-tenant.
terminate_instances() {
	echo "==> Terminating instances..."
	instance_ids=`list_instance_ids`
	success_or_die

	for instance in $instance_ids; do
		echo -n "	Terminating $instance..."
		nova delete $instance
		check_status_quietly $?
	done
	echo "==> Done"
}

#################### TROVE ####################

# Lists the ids of all trove backups of the given user-tenant.
list_trove_backup_ids() {
	trove backup-list | grep -i "^| " | grep -vi "^| *id *|" | awk '{ print $2 }'
}

# Deletes all trove backups for the tenant of the given user-tenant.
delete_trove_bakups() {
	echo "==> Deleting trove backups..."
	local trove_backup_ids=$(list_trove_backup_ids)
	success_or_die

	for trove_backup_id in $trove_backup_ids; do
		echo -n "	Deleting $trove_backup_id..."
		trove backup-delete $trove_backup_id
		check_status_quietly $?
	done
	echo "==> Done"
}

# List the ids of all trove instances of the given user-tenant.
list_trove_ids() {
	trove list | grep -i "^| " | grep -vi "^| *id *|" | awk '{ print $2 }'
}

# Deletes all trove instances of the given user-tenant.
delete_trove_instances() {
	echo "==> Deleting trove instances..."
	local trove_ids=$(list_trove_ids)
	success_or_die

	for trove_id in $trove_ids; do
		echo -n "	Deleting $trove_backup_id..."
		trove delete $trove_id
		check_status_quietly $?
	done
	echo "==> Done"
}

#################### GLANCE ####################

# Lists the ids of all images and snapshots of the given tenant.
list_image_ids() {
	glance image-list --owner $tenant_id | grep -i "^| " | grep -v "ID" | awk '{ print $2 }'
}

# Removes the images and snapshots of the given user-tenant.
delete_images() {
	echo "==> Deleting images and snapshots..."
	local image_ids=$(list_image_ids)
	success_or_die

	for image in $image_ids; do
		echo -n "   Deleting $image..."
			glance image-update --is-public=False --is-protected=False $image
			nova image-delete $image
			check_status_quietly $?
	done
	echo "==> Done"
}

#################### CINDER ####################

# List the ids of all volume snapshots of the given user-tenant.
list_volume_snapshot_ids() {
	cinder snapshot-list |  grep -i "^| " | grep -v "^| *ID *|" | awk '{ print $2 }'
}

# Deletes all volume snapshots of the given user-tenant.
delete_volume_snapshots() {
	echo "	==> Deleting volume snapshots..."
	local volume_snapshot_ids=$(list_volume_snapshot_ids)
	success_or_die

	for volume_snapshot_id in $volume_snapshot_ids; do
		echo -n "		Deleting snapshot $volume_snapshot_id..."
		cinder snapshot-delete $volume_snapshot_id
		check_status_quietly $?
	done
	echo "	==> Done"
}

# List the ids of all volumes of the given user-tenant.
list_volume_ids() {
	cinder list | grep -i "^| " | grep -v "^| *ID *|" | awk '{ print $2 }'
}

# Receivers the volume id that is being checked.
# returns 0, if there is snapshot volumes to be deleted, returns 1 otherwise.
check_snapshot_exists() {
	local volume_snapshot_ids=$(list_volume_snapshot_ids)

	if [ ! -z "$volume_snapshot_ids" ]; then
		return 0
	fi
	return 1
}

# Deletes all volumes of the given user-tenant.
delete_volumes() {
	echo "==> Deleting volumes..."
	local volume_ids=$(list_volume_ids)
	success_or_die

	delete_volume_snapshots

	for volume_id in $volume_ids; do
		echo -n "   Deleting $volume_id..."
		if check_snapshot_exists $volume_id ; then
			while check_snapshot_exists $volume_id; do
				echo -n ".";
				sleep 3;
			done
		fi
		cinder delete $volume_id
		check_status_quietly $?
	done
	echo "==> Done"
}

#################### NEUTRON ####################

# List the ids of all router of the given user-tenant.
list_routers() {
	neutron router-list 2>/dev/null | grep -i "^|" | grep -v "| *id *|" | awk '{ print $2 }'
}

# Lists all ports linked to the given router.
# param $1:
#	The router id.
list_router_ports() {
	neutron router-port-list $1 2>/dev/null | grep -i "^|" | grep -v "^| *id *|" | awk '{ print $2 }'
}

# Deletes all routers of the given user-tenant.
delete_routers() {
	echo "==> Deleting routers..."
	local router_ids=$(list_routers)
	success_or_die

	for router_id in $router_ids; do
		echo -n "   Deleting $router_id..."
		local router_port_ids=$(list_router_ports $router_id)
		for router_port_id in $router_port_ids; do
			neutron router-interface-delete $router_id port=$router_port_id 2>/dev/null
		done
		neutron router-delete $router_id 2>/dev/null
		check_status_quietly $?
	done
	echo "==> Done"
}

# List all ports belonging to the given subnet.
# param $1:
#	The subnet id
list_ports() {
	neutron port-list 2>/dev/null | grep -i "subnet_id....$1" | awk '{ print  $2}'
}

# Deletes the given port.
# param $1:
#	The port id
delete_port() {
	neutron port-delete $1 2>/dev/null
	echo -n "."
}

# List the ids of all subnets of the given user-tenant.
list_subnets_ids() {
	local subnet_ids=$(neutron subnet-list 2>/dev/null | grep -i "^|" | grep -v "^| *id *|" | awk '{ print $2 }')
	for subnet_id in $subnet_ids; do
		local subnet_tenant_id=$(neutron subnet-show $subnet_id 2>/dev/null | grep -i "^| *tenant_id *|" | awk '{ print $4 }' )
		if [ "$subnet_tenant_id" == "$tenant_id" ]; then
			echo $subnet_id
		fi
	done
}

# Deletes all subnets, and thereby all ports belonging to these subnets.
delete_subnets() {
	echo "==> Deleting subnets..."
	local subnet_ids=$(list_subnets_ids)

	for subnet_id in $subnet_ids; do
		echo -n "   Deleting $subnet_id..."
		local port_ids=$(list_ports $subnet_id)

		for port_id in $port_ids; do
			delete_port $port_id 2>/dev/null
		done
		neutron subnet-delete $subnet_id 2>/dev/null
		check_status_quietly $?
	done
	echo "==> Done"
}

# Lists the ids of all networks of the given user-tenant.
list_net_ids() {
	local net_ids=$(neutron net-list 2>/dev/null | grep -i "^|" | grep -v "| *id *|" | awk '{ print $2 }')
	for net_id in $net_ids; do
		local net_tenant_id=$(neutron net-show $net_id 2>/dev/null | grep -i "^| *tenant_id *|" | awk '{ print $4 }')
		if [ "$net_tenant_id" == "$tenant_id" ]; then
			echo $net_id
		fi
	done
}

# Deletes all networks of the given user-tenant.
# Note that you must only call this method after having successfully
# deleted all routers, subnets and ports beloging to this network.
delete_nets() {
	echo "==> Deleting nets..."
	local net_ids=$(list_net_ids)
	for net_id in $net_ids; do
		echo -n "   Deleting $net_id..."
		neutron net-delete $net_id 2>/dev/null
		check_status_quietly $?
	done
	echo "==> Done"
}

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

# Load the credentials of the user that is being deleted.
# This will look for the credentials file on the directory specified on environments.sh
load_creadentials() {
	local credentials_file=$CREDENTIALS_DIR/$guest_username-openrc.sh;
	if [ ! -e $credentials_file ]; then
		echo_fail "The crendentials of this user does not exists.";
		exit 1;
	elif [ ! -s $credentials_file ]; then
		echo_fail "The file with the credentials seems to be empty. Please check it.";
		exit 1;
	fi
	source $credentials_file;
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

	check_tenant;
	success_or_die;

	load_creadentials;
	success_or_die;
}



########## MAIN ##########

main() {
	define_parameters $@;
	success_or_die;

	delete_trove_bakups
	delete_trove_instances
	terminate_instances
	delete_images
	delete_volumes
	delete_routers;
	delete_subnets;
	delete_nets;
}

main $@;
