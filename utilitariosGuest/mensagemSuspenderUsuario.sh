#!/bin/bash

echo "Ola $1. Gostariamos de informar que sua conta foi SUSPENSA de acordo 
com nossas politicas de acesso. Apos 24 horas, sua conta sera removida do nosso sistema.

Para mais informa��es, entre em contato com a adminstra��o da nuvem CITTA

Obrigado" | mail -s "Suspensão de conta Openstack"  $2

