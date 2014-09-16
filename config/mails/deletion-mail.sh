#!/bin/bash

SENDER="heitor@silibrina.com"

send_confirmation_email() {
	mail -s "Sua conta na nuvem do CITTA foi removida" -r $SENDER -t $guest_email << EOF
Olá, $guest_username.
Sua conta na nuvem do CITTA foi removida permanentemente, entre em contato com alguém aí pra dar um jeito nisso.
EOF
}

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
		esac
		shift
	done
}

define_parameters $@
send_confirmation_email
