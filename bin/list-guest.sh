#!/bin/bash
######################### CONFIG #########################

source ../config/environment.sh

############# CHECKING PARAMETERS ##############

list_guests() {
	while read user; do
		local guest_username=$(echo $user | awk -F\: '{ print $1 }')
		local guest_email=$(echo $user | awk -F\: '{ print $2 }')
		echo -e "$guest_username \t\t $guest_email"
	done < $GUESTS_FILE
}

main() {
	list_guests;
}

main $@
