#!/bin/bash

SENDER="heitor@silibrina.com"

send_confirmation_email() {
	mail -s "Bem vindo a nuvem do CITTA" -A $guest_credentials_file -r $SENDER -t $guest_email << EOF
Olá, $guest_username.
Bem vindo a nuvem do CITTA. Para acessar a página, visite o endereço http://cloud.citta.org.br.
Seu nome de usuário é $guest_username e sua senha é $guest_password.

Anexo segue suas credenciais para acesso via linha de comando.

Em caso de alguma dúvida ou problema, não exite em nos contactar.
(Bora melhorar essa mensagem.)
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
			-p | --password)
				shift
				guest_password=$1
				;;
			-c | --credentials_file)
				shift
				guest_credentials_file=$1
		esac
		shift
	done
}

define_parameters $@
send_confirmation_email
