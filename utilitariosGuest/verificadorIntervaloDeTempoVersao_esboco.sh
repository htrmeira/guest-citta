#!/bin/bash

# Pegando o nome do sujeito e separando a data da criaÃ§ao:
usuario=$(cat dataCriacaoDeGuest.txt | awk '{print $1}')
tempoRef=$(cat dataCriacaoDeGuest.txt | awk '{print $3}')

# Pegando a data e hora de referencia
#diaRef="10#$(date +"%d/%m/%Y")"
#tempoRef="10#$(date +"%T")"

# Pega o ano, mes e dia
#anoRef=$(echo $diaRef | cut -d'/' -f3)
#mesRef=$(echo $diaRef | cut -d'/' -f2)
#diaRef=$(echo $diaRef | cut -d'/' -f1)

# Pega hora, minuto e segundo
#horaRef="10#$(echo $tempoRef | cut -d':' -f1)"
#minutoRef="10#$(echo $tempoRef | cut -d':' -f2)"
#segundoRef="10#$(echo $tempoRef | cut -d':' -f3)"

#deletou=0

#while [ $deletou -ne 1 ]; do

# Pegando a data e hora atual para comparar com a referencia
#diaAtual="10#$(date +"%d/%m/%Y")"
tempoAtual=$(date +"%s")

# Pega hora, minuto e segundo
#horaAtual=$(echo $tempoAtual | cut -d':' -f1)
#minutoAtual=$(echo $tempoAtual | cut -d':' -f2)
#segundoAtual=$(echo $tempoAtual | cut -d':' -f3)

# Se passou dois minutos em relacao ao dia de referencia, avisar que vai suspender conta:
#difMinutos=$((minutoAtual-minutoRef))

diffSegundos=$(($tempoAtual-$tempoRef))
diffMinutos=$(($diffSegundos / 60))

if [ $difMinutos -ge 2 ] && [ $difMinutos -lt 5 ]
	then
	echo "Passou mais de dois minutos. Suspender conta."
	/home/openstack/utilitariosGuest/suspenderUsuarioOcioso.sh $usuario
	sleep 60
	# Se passou mais que cinco minutos em relaÃcao ao dia de referencia, avisar que vai remover conta:
elif [ $difMinutos -ge 5 ]
	then
	echo "Passou mais de cinco minutos. Remover conta."
	/home/openstack/utilitariosGuest/removerUsuarioOcioso.sh $usuario
#	deletou=1
else
	echo "Nao passou nada. Continuar."
fi
sleep 1
#done
echo "Adeus."

# OBS: Os testes foram feitos usando um loop infinito - para deixar rodando em background, usar COMO ROOT:
# nohup /home/openstack/utilitariosGuest/verificadorIntervaloDeTempo.sh > /dev/null 2>&1 &
