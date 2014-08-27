#!/bin/bash


# Este script tem como objetivo identificar usuarios ociosos na instalacao da cloud CITTA.
# Um usuario é desabilitado apos 48 horas de inatividade no sistema.
# Estando desabilitado. apos 72 horas o usuario é permanentemente removido da cloud.


# Procedimento manual provisorio
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

source "/home/openstack/$1-openrc.sh"

# QUANDO FOR REMOVER USUARIO, DEVE TERMINAR INSTANCIAS, REMOVER VOLUMES, SNAPSHOTS, SNAPSHOTS DE VOLUMES, REDES (E ROTEADORES), E POSSIVELMENTE IMAGENS
# Terminando instancias
# Listando instancias:
nova list | grep -v "ID" | grep "^| " | awk '{print $2}' > "instancias$1.txt"

echo "Esta eh a lista de instancias:"
cat "instancias$1.txt"

# Terminando todas as instancias do individuo:
while read linha
do
        echo "Terminando a instancia $linha ..."
        nova delete $linha
        sleep 1
done < instancias$1.txt

rm instancias$1.txt

# Removendo Snapshots
# Precisa ser com as credenciais de admin
source "/home/openstack/admin-openrc.sh"
# Pega lista de imagens:
nova image-list | grep -v "ID" | grep "^| " | awk '{print $2}' > "imagens$1.txt"

echo "Esta eh a lista de imagens:"
cat "imagens$1.txt"

# Varrendo imagens para remover os snapshots do usuario $1:
# Da um image-show em cada uma e ve se o campo user_id eh o do usuario $1 , assim como se o campo image_location tem valor snapshot
while read imagemID
do
	donoImagem=$(keystone user-list | grep $1 | awk '{print $2}')
	sleep 2
	imagem_userID=$(nova image-show $imagemID | grep user_id | awk '{print $5}')
	sleep 2
	snapshot=$(nova image-show $imagemID | grep image_location | awk '{print $5}')
	sleep 2
	echo "donoImagem eh $donoImagem e imagem_userID eh $imagem_userID"
	if [ "$donoImagem" == "$imagem_userID" ]; then
		echo "snapshot eh $snapshot"
		if [ "$snapshot" == "snapshot" ]; then
			nova image-delete $imagemID
			echo "Removendo o Snapshot $imagemID ..."
			sleep 1
		fi
	fi
done < imagens$1.txt

rm imagens$1.txt

# Volta para as credenciais do individuo
source "/home/openstack/$1-openrc.sh"

# Removendo Snapshots de Volumes
# Pega lista de Snapshots de Volumes
cinder snapshot-list | grep -v "ID" | grep "^| " | awk '{print $2}' > "SnapVolumes$1.txt"

# Removendo os Snapshots dos Volumes
while read SnapVolume
do
	cinder snapshot-delete $SnapVolume
        echo "Removendo o Snapshot de Volume $SnapVolume  ..."
        sleep 1
done < SnapVolumes$1.txt

rm SnapVolumes$1.txt

# Removendo Volumes
# Pega lista de Volumes
cinder list | grep -v "ID" | grep "^| " | awk '{print $2}' > "volumes$1.txt"

# Removendo os Snapshots dos Volumes
while read volume
do
        cinder delete $volume
        echo "Removendo o Volume $volume  ..."
        sleep 1
done < volumes$1.txt

rm volumes$1.txt

# Removendo Roteadores e Redes
# OBS: Objetos criados pelo Neutron pertencem ao PROJETO $1 e nao ao usuario
# Removendo a porta do roteador que liga a subrede
# Varre a lista de portas ativas e suas respectivas subredes associadas:
neutron port-list | grep -v "ID" | grep -v "fixed_ips" | grep "^| " | tr -d \" | tr -d \, | awk '{print $2, "\t",  $8}' > "neutronSubRedes$1.txt"
sleep 2
neutron router-list | grep -v "ID" | grep "^| " | grep -v "name" | awk '{print $4}' > "neutronRouterList$1.txt"
sleep 2

while read porta
do
	echo "Trabalhando com a porta $porta"
	subRedeID=$(echo $porta | awk '{print $2}')
	echo "Pegou subrede de id $subRedeID"
	sleep 2
        nomeSubRede=$(neutron subnet-show $subRedeID | grep -w name | awk '{print $4}')
	echo "Pegou o nome de subrede $nomeSubRede"
	sleep 2
	while read roteadores
	do
		# Soh vai conseguir remover a porta do roteador correto,
		# e soh vai conseguir remover o roteador que teve a porta removida
		echo "Removendo porta do roteador $roteadores"
		neutron router-interface-delete $roteadores $nomeSubRede
		sleep 2
		echo "Removendo roteador..."
		neutron router-delete $roteadores
		sleep 2
	done < neutronRouterList$1.txt
	redeID=$(neutron subnet-show $subRedeID | grep -w network_id | awk '{print $4}')
	echo "Removendo subrede $nomeSubRede"
	neutron subnet-delete $nomeSubRede
	sleep 2
	echo "Removendo rede $redeID"
	neutron net-delete $redeID
	sleep 2
done < neutronSubRedes$1.txt

rm neutronSubRedes$1.txt
rm neutronRouterList$1.txt

# Removendo usuario de fato
# Precisa das credenciais do admin
source "/home/openstack/admin-openrc.sh"
echo "Removendo usuario $1:"
keystone user-delete $1
sleep 1
keystone tenant-delete $1
sleep 1
# OBS: A proxima linha assume que o arquivo esta no diretorio /home do usuario openstack
echo "Removendo arquivo de credenciais de usuario:"
rm /"home/openstack/$1-openrc.sh"
sleep 1
echo "Usuario removido. Esta eh a relaçao atual de usuarios:"
keystone user-list
