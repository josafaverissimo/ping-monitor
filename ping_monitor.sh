#!/usr/bin/env bash
#
# ./ping_monitor ~ get average ms from domains
#
# Author: Josafá Veríssimo
# Email: josafaverissimo98@gmail.com
# --------------------------------------------------------
# A command line monitor to view average ms from domains
# 
# Example:
#	> ./ping_monitor
#		The script will monitorate domain that is hardcoded
# --------------------------------------------------------
# Bash version: 5.1.16
#
# --------------------------------------------------------
#
# Functions ----------------------------------------------

function getWords() {
	string=$1

	grep -o [a-zA-Z] <<< "$url" | tr -d "\n"
}

function killProccess() {
	pids=$*

	for pid in $pids; do
		kill -kill $pid > /dev/null 2>&1
	done
}

function doPing() {
	urls=$*
	input=""
	stop_flag="q"
	lines=$(tput lines)

	declare -A ping_pids_array
	declare -A icmp_seq_array
	declare -A ms_sum_array
	declare -A ms_avg_array
	declare -A tput_line_position_array
	line_counter=0

	for url in $urls; do
		file_ping_data=$(getWords "$url")

		icmp_seq_array["$file_ping_data"]=1
		ms_sum_array["$file_ping_data"]=0
		ms_avg_array["$file_ping_data"]=0
		tput_line_position_array["$file_ping_data"]=$line_counter
		
		((line_counter++))

		ping $url > "./.temp_$file_ping_data" &
		ping_pids_array["$file_ping_data"]=$!
	done

	while :; do
		for url in $urls; do
			ms=""
			file_ping_data=$(getWords "$url")	
			icmp_seq=${icmp_seq_array["$file_ping_data"]}
			ms_sum=${ms_sum_array["$file_ping_data"]}

			while [[ -z "$ms" ]]; do
				sleep 1

				ms=$(grep seq=$icmp_seq ./.temp_$file_ping_data \
					| head -n 1 \
					| cut -d ' ' -f 8 \
					| cut -d '=' -f 2)

				ms_sum_array["$file_ping_data"]=$(python3 -c\
					"print('{:.2f}'.format($ms + $ms_sum))")
				ms_avg_array["$file_ping_data"]=$(python3 -c\
					"print('{:.2f}'.format($ms_sum/$icmp_seq, 2))")
 
				tput cup ${tput_line_position_array["$file_ping_data"]} 0
				echo "$url" ${ms_avg_array["$file_ping_data"]}"ms"
			done

			((icmp_seq_array["$file_ping_data"]++))
		done
	done &
	while_pid=$!

	while :; do
		tput cup $(tput lines - 1)
		read -p "~press q to quit" -n 1 input

		if [[ "$input" = "$stop_flag" ]]; then
			killProccess $while_pid ${ping_pids_array[@]}

			for url in $urls; do
				file_ping_data=$(getWords "$url")

				rm -rf "./.temp_$file_ping_data"
			done
			break
		fi
	done
	
}

# --------------------------------------------------------
#
# Execution ----------------------------------------------

tput clear
tput civis

doPing www.microsoft.com www.google.com.br www.instagram.com.br www.facebook.com

tput clear
tput cnorm
# --------------------------------------------------------
