#!/bin/bash

# Le o dataDeCriacao e verifica linha por linha
# Em cada linha, pega o nome do usuario e roda o que esta dentro do laco

log_dir=/home/openstack/utilitariosGuest/logs/

date >> $log_dir/debug.txt
while read linha
do

usuario=$(echo $linha | awk '{print $1}')
tempoUsuario=$(echo $linha | grep $usuario | awk '{print $3}')
tempoAtual=$(date +"%s")
diffSegundos=$(($tempoAtual - $tempoUsuario))
diffMinutos=$(($diffSegundos / 60))
suspendeu=$(echo $linha | awk '{print $5}')

#tempo producao: 48 = 2880
#                72 = 4320

echo "================================================" >> $log_dir/debug.txt
echo "usuario: $usuario" >> $log_dir/debug.txt
echo "tempo_usuario: $tempoUsuario" >> $log_dir/debug.txt
echo "tempo_atual: $tempoAtual" >> $log_dir/debug.txt
echo "tempo_segundos: $diffSegundos" >> $log_dir/debug.txt
echo "tempo_minutos: $diffMinutos" >> $log_dir/debug.txt
echo "suspendeu: $suspendeu" >> $log_dir/debug.txt
echo "$(($diffMinutos/60)) horas se passaram" >> $log_dir/debug.txt

if [ $diffMinutos -ge 2880 ] && [ $diffMinutos -lt 4320 ] && [ $suspendeu -ne 1 ]
    then
	echo "caiu_no_primeiro_if" >> $log_dir/debug.txt
    /home/openstack/utilitariosGuest/suspenderUsuarioOcioso.sh $usuario
	sed  -e '/^'$usuario'/{ s/0$/1/ }'  /home/openstack/utilitariosGuest/dataCriacaoDeGuest.txt
	echo -e "------suspensao de $usuario com sucesso" >> $log_dir/debug.txt
elif [ $diffMinutos -ge 4320 ]
    then
	echo "caiu_no_elif" >> $log_dir/debug.txt
    /home/openstack/utilitariosGuest/removerUsuarioOcioso.sh $usuario 
	sed -i /"$linha"/d /home/openstack/utilitariosGuest/dataCriacaoDeGuest.txt
	echo -e "------remocao de $usuario com sucesso" >> $log_dir/debug.txt
else
	echo "caiu_no_else" >> $log_dir/debug.txt
	echo -e "------nada feito para $usuario" >> $log_dir/debug.txt

fi

echo  "================= terminou_while ================= " >> $log_dir/debug.txt
echo  " " >> $log_dir/debug.txt
sleep 1
done < /home/openstack/utilitariosGuest/dataCriacaoDeGuest.txt



#echo "logs verificador de tempo" | mutt "envio" -a $log_dir/$usuario-$data.txt -- guilherme.pimentel@ccc.ufcg.edu.br



