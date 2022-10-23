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
#	> ./ping_monitor www.github.com www.google.com
#		The script will monitorate hosts in paramaters
#		if you create a file hosts.txt in the same dir,
#		the script will monitorate hosts in file too
#
#	> ./ping_monitor --no-sleep
#		The script will be execute with no sleep
#
#	> ./ping_monitor --no-sleep www.github www.google.com
#		no sleep with hosts options. The position of
#		"--no-sleep" doesn't matter
#
# --------------------------------------------------------
# Bash version: 5.1.16
#
# --------------------------------------------------------
#
# Variables ----------------------------------------------

URLS=""
NO_SLEEP_FLAG=0

# Functions ----------------------------------------------

function getWordsAndNumbers() {
	string=$1

	grep -o [a-zA-Z0-9] <<< "$string" | tr -d "\n"
}

function killProccess() {
	pids=$*

	for pid in $pids; do
		kill -kill $pid > /dev/null 2>&1
	done
}

function doPing() {
	[[ -z "$*" ]] && exit 0	

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
		file_ping_data=$(getWordsAndNumbers "$url")

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
			file_ping_data=$(getWordsAndNumbers "$url")	
			icmp_seq=${icmp_seq_array["$file_ping_data"]}
			ms_sum=${ms_sum_array["$file_ping_data"]}

			while [[ -z "$ms" ]]; do
				[[ $NO_SLEEP_FLAG -eq 0 ]] && sleep 1

				ms=$(grep seq=$icmp_seq ./.temp_$file_ping_data \
					| head -n 1 \
					| cut -d '=' -f 4 \
					| cut -d ' ' -f 1)

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
				file_ping_data=$(getWordsAndNumbers "$url")

				rm -rf "./.temp_$file_ping_data"
			done
			break
		fi
	done
	
}

# --------------------------------------------------------
#
# Execution ----------------------------------------------

[[ -f "./hosts.txt" ]] && URLS=$(cat hosts.txt | tr "\n" " ")
if [[ -n "$*" ]]; then
	if [[ -n "$URLS" ]]; then
		for url in $*; do
			case $url in
				--no-sleep) NO_SLEEP_FLAG=1 && continue;;
			esac

			isnt_in_urls=$(echo $URLS | grep -w $url)

			[[ -z "$isnt_in_urls" ]] && URLS="$URLS $url"
		done
	else
		URLS="$*"
	fi
fi

tput clear
tput civis

doPing $URLS

tput clear
tput cnorm
# --------------------------------------------------------
