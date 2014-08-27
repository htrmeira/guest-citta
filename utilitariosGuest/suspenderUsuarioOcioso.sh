#!/bin/bash


# Este script tem como objetivo suspender um usuario ocioso por 48 horas.
# Um e-mail éenviado para o usuario informando-o que sua conta foi desabilitad
# e que será permanentemente removida apos mais 24 horas


# Pegando as credenciais do individuo (argumento $1 do script): Assumindo o caminho /home/openstack
source "/home/openstack/$1-openrc.sh"


# Listando instancias:
nova list | grep -v "ID" | grep "^| " | awk '{print $2}' > "instancias$1.txt"

echo "Esta eh a lista de instancias:"
cat "instancias$1.txt"

# Dando suspend em todas as instancias do individuo:
while read linha
do
		echo "Dando suspend na instancia $linha ..."
        nova suspend $linha
        sleep 1
done < instancias$1.txt

rm instancias$1.txt

echo "Suspendendo o projeto do usuario:"
source "/home/openstack/admin-openrc.sh"

keystone tenant-update $1 --enabled=disable


#Pegando email do usuario
email=$(keystone user-list | grep $1 | grep -E -o "\b[a-zA-Z0-9.-]+@[a-zA-Z0-9.-]+\.[a-zA-Z0-9.-]+\b")


#enviando notificacao para usuario
/home/openstack/utilitariosGuest/mensagemSuspenderUsuario.sh $1 $email



