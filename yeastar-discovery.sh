#!/bin/bash
# 2019/05/24 AcidVenom v1.0
# 2021/09/21 Wamazeka v1.1
# Script LLD-discovery SIM-cards via API Yeastar for Zabbix 
#
# Parameters: $discovery_2_3_etc $IP $API.USER $API.PASS

# Discovery information about installed SIM-cards
# key - discovery

IFS=$'\n'
JSON="{\"data\":["
SEP=""

if [[ $1 = "discovery" ]]
then
get=`echo -e "Action: Login\nUsername: $3\nSecret: $4\n\nAction: smscommand\nCommand: gsm show spans\n\nAction: Logoff\n\n" | nc $2 5038 | grep "span [0-9]*:"`
for pool in $get
do
id=`echo $pool | sed "s/.* span //g" | sed "s/:.*//g"`
# Examples:
# GSM span 2: Power on, Provisioned, Up, Active,Standard
# GSM span 7: Power on, Provisioned, Undetected SIM Card, Active,Standard
# So, for ID just crop after 'span' and before ':'

num=$(($id-1))
power=`echo $pool | grep "span [0-9]*:" | sed "s/.*: //g" | sed "s/,.*//g"`
# For Power crop after ':' and after first ','
status=`echo $pool | grep "span [0-9]*:" | sed "s/.*: //g"  | sed "s/^.*, \(.*\), .*/\1/g"`

JSON=$JSON"$SEP{\"{#ID}\":\"$id\", \"{#NUM}\":\"$num\", \"{#POWER}\":\"$power\", \"{#STATUS}\":\"$status\"}"
SEP=", "
done
JSON=$JSON"]}"
echo $JSON

# Get information about certain SIM-card
# key - from discovery ("2", "3" etc.)

else
echo -e "Action: Login\nUsername: $3\nSecret: $4\n\nAction: smscommand\nCommand: gsm show span $1\n\nAction: Logoff\n\n" | nc $2 5038

fi
