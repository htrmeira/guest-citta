#!/bin/bash

echo "Ola $1. Gostariamos de informar que sua conta foi SUSPENSA de acordo 
com nossas politicas de acesso. Apos 24 horas, sua conta sera removida do nosso sistema.

Para mais informações, entre em contato com a adminstração da nuvem CITTA

Obrigado" | mail -s "SuspensÃ£o de conta Openstack"  $2

