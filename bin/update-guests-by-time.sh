#!/bin/bash

# This script checks all guest users on $GUESTS_FILE and updates
# his status by suspending or deleting them based on the time of creation.
# param $1:
#	-c | --credentials: the path to acredentials file of a admin user.

##################### CONFIG ####################

# The parent directory where the script is installed.
PARENT_DIR=/home/heitor/workspace/guest-citta

# The bin dir inside the parent dir.
# This is the directory that stores the main scripts.
BIN_DIR=$PARENT_DIR/bin

# This is the time for suspend a user after his creation.
# Here we have 48h in seconds.
SUSPENSION_TIME=172800
#SUSPENSION_TIME=60

# This is the time for delete a user after his creation.
# Here we have 48h in seconds.
# 72h in seconds
DELETION_TIME=259200
#DELETION_TIME=180

# The current time in seconds.
CURRENT_TIME=$(date +'%s')

cd $BIN_DIR
source /etc/environment
source $PARENT_DIR/config/environment.sh

################## CONSTANTS #################

# When the user is active
ACTIVE_STATUS=0

# When the user is already suspended.
SUSPENDED_STATUS=1

############## LOCAL FUNCTIONS #############

# Receives a user and echoes his time of creation in seconds.
# param $1:
#	A user following the format 'username : email : date of creation in seconds : ...'
get_created_at() {
	echo $1 | awk -F\: '{ print $3 }' | tr -d ' '
}

# Receives a user and echoes his status ( 0 for active, 1 if suspended);
# param $1:
#	A user following the format 'username : email : date of creation in seconds : status : ...'
get_status() {
	echo $1 | awk -F\: '{ print $4 }' | tr -d ' '
}

# Receives a user and echoes his username .
# param $1:
#	A user following the format 'username : ...'
get_guest_username() {
	echo $1 | awk -F\: '{ print $1 }' | tr -d ' '
}

# Runs the script that suspends a guest user.
# param $1:
#	The username of the guest.
suspend_guest() {
	$BIN_DIR/suspend-guest.sh --username $1
}

# Runs the script that delets a guest user his tenant.
# param $1:
#	The username of the guest.
delete_guest() {
	$BIN_DIR/delete-guest.sh --username $1
}

# Update the status of a user.
# It will iterate of all users on $GUESTS_FILE and calculate
# if it is time for suspend or delete a user.
# Note that even if it is time for delete the user, it will first suspend it.
run_update() {
	while read guest_user; do
		echo "======= [`date`] - checking: [$guest_user] ======="
		local created_at_in_sec=$(get_created_at "$guest_user")
		local creation_duration=$(($CURRENT_TIME - $created_at_in_sec))
		local guest_status=$(get_status "$guest_user")
		local guest_username=$(get_guest_username "$guest_user")

		if [ $creation_duration -ge $SUSPENSION_TIME ] &&
			[ $guest_status == $ACTIVE_STATUS ]; then
			suspend_guest $guest_username
		elif [ $creation_duration -ge $DELETION_TIME ] &&
			[ $guest_status == $SUSPENDED_STATUS ]; then
			delete_guest $guest_username
		fi
		echo "======= [`date`] - finished: [$guest_user] ======="
	done < $GUESTS_FILE
}

# Loads the credentials of a user.
# This user must a admin one.
# param $1:
#	The path of credentials file.
load_credentials() {
	if [ -z $1  ]; then
		echo_fail "You must specify a credentials file"
		exit 1;
	elif [ ! -e $1 ]; then
		echo_fail "The crendentials of this user does not exists.";
		exit 1;
	elif [ ! -s $1 ]; then
		echo_fail "The file with the credentials seems to be empty. Please check it.";
		exit 1;
	else
		source $1
	fi
}

show_help() {
	echo "Paramters inside [] are not mandatory"
	echo "Usage:  $0 -c | --credentials PATH_TO_CREDENTIALS_FILE"
	echo -e "\t$0 -h | --help"
	echo
	echo "-c | --credentials: the credentials file os an admin user (MANDATORY)"
	echo "-h | --help: shows this help"
}

# Define the arguments provided for this is script as variables and checks if it is all ok.
define_parameters() {
	while [ ! -z $1 ]; do
		case $1 in
			-c | --credentials)
				shift;
				credentials_file=$1;
				;;
			*)
				show_help;
				exit 0;
				;;
		esac
		shift
	done
	load_credentials $credentials_file;
	success_or_die;
}

###################### MAIN ####################

main() {
	define_parameters $@;
	success_or_die;

	run_update;
}

main $@;
