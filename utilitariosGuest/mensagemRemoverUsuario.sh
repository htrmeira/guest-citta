#!/bin/bash

echo "Ola $1. Gostariamos de informar que sua conta foi REMOVIDA de acordo 
com nossas politicas de acesso.

Para mais informa�ões, entre em contato com a adminstra��o da nuvem CITTA

Obrigado" | mail -s "Exclus�o de conta Opensck" $2

