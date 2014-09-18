#!/bin/bash
######################### CONFIG #########################

source ../config/environment.sh

############# CHECKING PARAMETERS ##############

list_guests() {
	while read user; do
		local guest_username=$(echo $user | awk -F\: '{ print $1 }')
		local guest_email=$(echo $user | awk -F\: '{ print $2 }')
		local guest_created_at=$(echo $user | awk -F\: '{ print $3 }')
		local guest_status=$(echo $user | awk -F\: '{ print $4 }'| sed -e 's/0/ACTIVE/g' | sed -e 's/1/SUSPENDED/g')
		echo -e "$guest_username \t\t $guest_email \t\t $guest_status \t\t $(date -d @$(echo $guest_created_at))"
	done < $GUESTS_FILE
}

main() {
	list_guests;
}

main $@
