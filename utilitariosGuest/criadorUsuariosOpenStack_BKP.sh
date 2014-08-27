#!/bin/bash

# Este script se baseia em dados que sao fornecidos por um individuo que deseja se tornar um usuario do OpenStack.
# Se conhece o nome de usuario e sua senha
# OBS: Este script eh para ser rodado como o usuario admin, ou qualquer outro usuario com
# direitos administrativos. Rode o script como ROOT, se puder.
usuario=$1
senhaUsuario=$2
emailUsuario=$3

# Sequencia de comandos para criar um usuario:
echo "Aguarde enquanto o usuario esta sendo criado:"
keystone user-create --name=$usuario --pass=$senhaUsuario --email=$emailUsuario
sleep 3
keystone tenant-create --name=$usuario --description="Projeto criado para o usuario $usuario"
sleep 3
keystone user-role-add --user=$usuario --role=convidado --tenant=$usuario
sleep 3

echo "Foi criado o usuario $usuario com a senha e endereÃ§o de email pedidos."
echo "Gerando um arquivo para suas credenciais, caso queira usar a CLI:"
sleep 1
touch /home/openstack/$usuario-openrc.sh
chmod +x /home/openstack/$usuario-openrc.sh
echo "export OS_USERNAME=$usuario" >> /home/openstack/$usuario-openrc.sh
echo "export OS_PASSWORD=$senhaUsuario" >> /home/openstack/$usuario-openrc.sh
echo "export OS_TENANT_NAME=$usuario" >> /home/openstack/$usuario-openrc.sh
echo "export OS_AUTH_URL=http://controller:35357/v2.0" >> /home/openstack/$usuario-openrc.sh

echo "Ok."
echo "O usuario foi criado com sucesso."
echo "O arquivo com as credenciais do individuo se encontra no diretorio /home/$(whoami) ."

#registrando a data de criaÃÃo do usuario em arquivo de texto
#com o formato usuario:data

#pega a quantidade de segundos em relacao ao unixtime
DATA=$(date +"%s")
#Esta data foi usada para testes
#DATA=$(date +"%T")

source "/home/openstack/$usuario-openrc.sh"

echo "$usuario : $DATA : "0"" >> dataCriacaoDeGuest.txt




