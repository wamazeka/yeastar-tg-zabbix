#!/bin/bash
# 2019/05/24 AcidVenom v1.0
# 2023/03/15 Wamazeka v1.2
# Script LLD-discovery SIM-cards via API Yeastar for Zabbix
#
# Parameters: $discovery_2_3_etc $IP $API.USER $API.PASS

# discovery -- Discovery information about installed SIM-cards
# scriptname.sh discovery IP_address APIUSER APIPASS

# balance -- get number balance
# scriptname.sh balance IP_address APIUSER APIPASS SPAN_NUM TIMEOUT_DEFAULT

# else -- get info about certain span
# scriptname.sh SPAN_NUM

declare -a USSD
USSD["79037011111"]="*102#" # Beeline
USSD["79262909090"]="*100#" # Megafon
USSD["79219909090"]="*100#" # Megafon_2
USSD["79202909090"]="*100#" # Megafon_3
USSD["79043490000"]="*105#" # Tele2
USSD["79168999100"]="*100#" # MTS
USSD["79112009993"]="*100#" # MTS_2

IFS=$'\n'
JSON="{\"data\":["
SEP=""

if [[ $1 = "discovery" ]]; then
	get=$(echo -e "Action: Login\nUsername: $3\nSecret: $4\n\nAction: smscommand\nCommand: gsm show spans\n\nAction: Logoff\n\n" | nc $2 5038 | grep "span [0-9]*:")

	for pool in $get; do
		# Examples for $pool:
		# GSM span 2: Power on, Provisioned, Up, Active,Standard
		# GSM span 7: Power on, Provisioned, Undetected SIM Card, Active,Standard
		# So, for span_num(ID) just crop after 'span' and before ':'

		#echo $pool
		id=$(echo $pool | sed "s/.* span //g" | sed "s/:.*//g")
		#echo $id

		num=$(($id - 1))
		power=$(echo $pool | grep "span [0-9]*:" | sed "s/.*: //g" | sed "s/,.*//g")
		# For Power crop after ':' and after first ','
		status=$(echo $pool | grep "span [0-9]*:" | sed "s/.*: //g" | sed "s/^.*, \(.*\), .*/\1/g")

		JSON=$JSON"$SEP{\"{#ID}\":\"$id\", \"{#NUM}\":\"$num\", \"{#POWER}\":\"$power\", \"{#STATUS}\":\"$status\"}"
		SEP=", "
	done
	JSON=$JSON"]}"
	echo $JSON
fi

if [[ $1 = "balance" ]]; then
	smscenter=$(echo -e "Action: Login\nUsername: $3\nSecret: $4\n\nAction: smscommand\nCommand: gsm show span $5\n\nAction: Logoff\n\n" | nc $2 5038 | grep 'SMS Center' | tr -d [:blank:] | tr -d [:alpha:] | tr -d :+)

	ussdresponce=$(echo -e "Action: Login\nUsername: $3\nSecret: $4\n\nAction: smscommand\nCommand: gsm send ussd $5 ${USSD["$smscenter"]} $7\n\nAction: Logoff\n\n" | nc $2 5038 | grep "USSD Message")

	# Uppercase for minus catching, delete all spaces, change comma to dot
	ussdresponce=$(echo $ussdresponce | tr [:lower:] [:upper:] | tr -d [:blank:] | tr , . | tr -d :)

	# catch minus
	ussdresponce=${ussdresponce//'MINUS'/'-'}
	#ussdresponce=${ussdresponce//'МИНУС'/'-'} #russian non correct in proxmox , catch in template
	#ussdresponce=${ussdresponce//'Р.'/''} #russian non correct in proxmox , catch in template
	ussdresponce=${ussdresponce//'P.'/''}

	# delete all spaces, all letters
	# ussdresponce=$(echo $ussdresponce | tr -d [:blank:] | tr -cd "1234567890.-") # work in template

	echo $ussdresponce
fi

if [[ $1 = "info" ]]; then
	echo "get into get info"
	# Get information about certain SIM-card
	# key - from discovery ("2", "3" etc.)
	echo -e "Action: Login\nUsername: $4\nSecret: $5\n\nAction: smscommand\nCommand: gsm show span $2\n\nAction: Logoff\n\n" | nc $3 5038

fi
