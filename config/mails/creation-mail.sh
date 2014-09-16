#!/bin/bash

SENDER="heitor@silibrina.com"

send_confirmation_email() {
	#mail -s "$(echo -e "Bem vindo a nuvem do CITTA\nContent-Type: text/html")" -A $guest_credentials_file -r $SENDER -t $guest_email << EOF
	#mail -s "Bem vindo a nuvem do CITTA" -r $SENDER -t $guest_email -a 'Content-Type: text/html;' --content-type="Content-Type: text/html" -A $guest_credentials_file  << EOF
	mail -A $guest_credentials_file -s  "$(echo -e "Bem vindo a nuvem do CITTA\nContent-Type: text/html")" -r $SENDER -t $guest_email --content-type="text/html"  -a 'Content-Type: text/html' -a 'Content-type: text/html; charset="utf-8"' << EOF
<html>
<body>
<p>Olá, <b>$guest_username</b>.</p>
</br>
</br>
<div>Bem vindo a nuvem do CITTA. Para acessar a página, visite o endereço <a href="http://cloud.citta.org.br">http://cloud.citta.org.br</a>.</div>
</br>
<div>
	<p>Seu nome de usuário é: <b>$guest_username</b> e sua senha é: <b>$guest_password</b></p>
</div>
</br>
<div>
	<p>Anexo segue suas credenciais para acesso via linha de comando.</p>
</div>
</br>
<div>
	<p>Você pode acessar um guia rápido de uso <a href="https://docs.google.com/document/d/1DIfC9pPsUlBaJ8VjCZRGghD_0N_YibRVzWJJfL9ptUo/edit?usp=sharing">aqui</a></p>
</div>
<div>
	<p>Em caso de dúvida ou problema, não exite em nos contactar.</p>
</div>
<div><p>Obrigado.</p></div>
<img src="http://citta.org.br/images/marca_citta.png" alt="Citta Logo" width=100 height=50>
</body>
</html>
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
