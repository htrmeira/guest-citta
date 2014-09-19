#!/bin/bash

SENDER="heitor@silibrina.com"

send_confirmation_email() {
	mail -s "$(echo -e "Sua conta na nuvem do CITTA foi suspensa\nContent-Type: text/html")" -a "From: CITTA Cloud <$SENDER>" -r $SENDER -t $guest_email << EOF

<p>Olá, <b>$guest_username</b>.</p>
</br>
</br>
<div>Informamos que sua conta foi <b>suspensa</b> de acordo com nossas politicas de acesso.</div>
<div>Apos 24 horas, sua conta sera removida do nosso sistema.</div></br>
</br>
<div><p>Para mais informações, entre em contato com a adminstração da nuvem CITTA.</p></div></br>
</br>
<div><p>Obrigado.</p></div>
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
