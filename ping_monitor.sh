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
# Exit codes ---------------------------------------------

UNDEFINED_EXIT_CODE=255
NO_URLS_EXIT_CODE=100
CANCELED_BY_USER_EXIT_CODE=200
SUCCESS_EXIT_CODE=0

# --------------------------------------------------------
#
# Variables ----------------------------------------------

URLS=""
NO_SLEEP_FLAG=0
HOSTS_FILE="./hosts.txt"
TEMP_FILE="./.temp$$"

# Functions ----------------------------------------------

function dialog_box() {
	# empty parameters?
	[[ -z "$*" ]] && exit $UNDEFINED_EXIT_CODE
	
	local title="Box"

	local is_input=0
	local input_message="Type a text"
	local input_value=""

	local is_textbox=0
	local textbox_data=""

	local is_menu=0
	local menu_message="choose a option:"
	local menu_options=""

	local is_msgbox=0
	local msgbox_text="hello"

	while [[ -n "$1" ]]; do
		parameter=$1

		# is the title?
		grep -E -q "^title.*$" <<< "$parameter"		
		if [[ $? -eq 0 ]]; then
			title=$(sed -r 's/title=//' <<< "$parameter")
		fi

		# is a inputbox?
		grep -E -q "^input$" <<< "$parameter"
		if [[ $? -eq 0 ]]; then
			is_input=1
		fi

		# there's a input message?
		grep -E -q "^input_message.*$" <<< "$parameter"
		if [[ $? -eq 0 ]]; then
			input_message=$(sed -r 's/input_message=//' <<< "$parameter")
		fi

		# there's a input value?
		grep -E -q "^input_value.*$" <<< "$parameter"
		if [[ $? -eq 0 ]]; then
			input_value=$(sed -r 's/input_value=//' <<< "$parameter")
		fi

		# is a textbox?
		grep -E -q "^textbox$" <<< "$parameter"
		if [[ $? -eq 0 ]]; then
			is_textbox=1
		fi

		# there's a textbox data?
		grep -E -q "^textbox_data.*$" <<< "$parameter"
		if [[ $? -eq 0 ]]; then
			textbox_data=$(sed -r 's/textbox_data=//' <<< "$parameter")
		fi

		# is a menu?
		grep -E -q "^menu$" <<< "$parameter"
		if [[ $? -eq 0 ]]; then
			is_menu=1
		fi

		# there's a menu message?
		grep -E -q "^menu_message.*$" <<< "$parameter"
		if [[ $? -eq 0 ]]; then
			menu_message=$(sed -r 's/menu_message=//' <<< "$parameter")
		fi

		# there's a menu options?
		grep -E -q "^menu_options.*$" <<< "$parameter"
		if [[ $? -eq 0 ]]; then
			menu_options=$(sed -r 's/menu_options=//' <<< "$parameter")
		fi

		# is a message box?
		grep -E -q "^msgbox$" <<< "$parameter"
		if [[ $? -eq 0 ]]; then
			is_msgbox=1
		fi

		# there's a message box text?
		grep -E -q "^msgbox_text.*$" <<< "$parameter"
		if [[ $? -eq 0 ]]; then
			msgbox_text=$(sed -r 's/msgbox_text=//' <<< "$parameter")
		fi

		shift
	done

	if [[ $is_input -eq 1 ]]; then
		dialog --title "$title" --stdout --inputbox "$input_message" 0 0 "$input_value"

		return $?
	fi

	if [[ $is_textbox -eq 1 ]]; then
		dialog --title "$title" --textbox "$textbox_data" 20 50

		return $?
	fi

	if [[ $is_menu -eq 1 ]]; then
		eval dialog --title \"$title\" --stdout --menu \"$menu_message\" 0 0 0 $menu_options

		return $?
	fi

	if [[ $is_msgbox -eq 1 ]]; then
		dialog --title "$title" --msgbox "$msgbox_text" 0 0

		return $?
	fi
}

function hosts_manager() {
	local option=

	function main_menu() {
		local box_title="Menu"
		local menu_message="Choose a option:"
		local menu_options="$(cat <<- EOF
			1 "Create host"
			2 "Read hosts"
			3 "Update host"
			4 "Delete host"
		EOF
		)"

		option=$(dialog_box title="$box_title" menu menu_options="$menu_options")
		cancel=$?

		echo "$option"

		return $cancel
	}

	function create_host() {
		local box_title="Add a host"
		local input_message="Type a domain or ip"
		local host=""

		host=$(dialog_box title="$box_title" input input_message="$input_message")
		[[ $? -ne 0 ]] && return $?
    
    if [[ -n $host ]]; then 
		  echo "$host" >> "$HOSTS_FILE"
  		dialog_box title="Success" msgbox msgbox_text="Host created"

		  return $?
    else
      dialog_box title="Failed" msgbox msgbox_text="Host is empty!" 

  		return $?
    fi

	}

	function read_hosts() {		
		local box_title="Show hosts"
		grep -E "^[a-zA-Z0-9]" "$HOSTS_FILE" > "$TEMP_FILE"

		
		dialog_box title="$box_title" textbox textbox_data="$TEMP_FILE"

		rm -f "$TEMP_FILE"
	}

	function update_host() {
		local box_title="Update host"
		local menu_message="Choose a host to update:"
		local menu_options="$(grep -E "^[a-zA-Z0-9]" $HOSTS_FILE | sed -r 's/^|$/"/g;s/$/ \//')"

		hostToUpdate=$(dialog_box title="$box_title" menu menu_options="$menu_options")
		[[ $? -ne 0 ]] && return $?

		newHost=$(dialog_box title="Update $hostToUpdate" input input_message="" input_value="$hostToUpdate")
		[[ $? -ne 0 ]] && return $?

		sed -i "s/$hostToUpdate/$newHost/g" $HOSTS_FILE

		dialog_box title="Success" msgbox msgbox_text="Host updated"
	}

	function delete_host() {
		local box_title="Delete host"
		local menu_message="Choose a host to delete:"
		local menu_options="$(grep -E "^[a-zA-Z0-9]" $HOSTS_FILE | sed -r 's/^|$/"/g;s/$/ \//')"

		hostToDelete=$(dialog_box title="$box_title" menu menu_options="$menu_options")
		[[ $? -ne 0 ]] && return $?

		grep -E -v "^$hostToDelete$" $HOSTS_FILE > "$TEMP_FILE"

		mv "$TEMP_FILE" "$HOSTS_FILE"

		dialog_box title="Success" msgbox msgbox_text="Host deleted"

	}

	while :; do
		option=$(main_menu)
		
		# exit menu?
		[[ $? -ne 0 ]] && return $CANCELED_BY_USER_EXIT_CODE

		case $option in
			1)
				create_host
				[[ $? -ne 0 ]] && return $CANCELED_BY_USER_EXIT_CODE
			;;
			2)
				read_hosts
				[[ $? -ne 0 ]] && return $CANCELED_BY_USER_EXIT_CODE
			;;
			3)
				update_host
				[[ $? -ne 0 ]] && return $CANCELED_BY_USER_EXIT_CODE
			;;
			4)
				delete_host
				[[ $? -ne 0 ]] && return $CANCELED_BY_USER_EXIT_CODE
			;;
		esac
	done
}

function help_menu() {
	tput clear
	tput cup 0 0
	
	help_message="$(cat <<- EOF
		$(basename $0)

		>OPTIONS
		-h ~ Help menu
		-mg ~ manage hosts
		--no-sleep ~ Monitorate without delay

		>Domains
		just type a host or multiple hosts. E.g.: $0 www.github.com www.google.com
	EOF
	)"

	help_message=$(echo "$help_message" | sed -r 's/\t//g')

	echo -e "$help_message"
}

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
	local urls="$(cat $HOSTS_FILE | tr '\n' ' ')"

	if [[ -n "$*" ]]; then
		for url in $*; do
			echo "$url" >> test.txt
			grep -q "$url" <<< $urls
			[[ $? -ne 0 ]] && urls="$urls $url"
		done
	fi


	[[ -z "$urls" ]] && exit $NO_URLS_EXIT_CODE

	local input=""
	local stop_flag="q"
	local quit_message="> q to quit"

	declare -A ping_pids_array
	declare -A icmp_seq_array
	declare -A ms_sum_array
	declare -A ms_avg_array
	declare -A tput_line_position_array
	local line_counter=0

	tput civis

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
		[[ $NO_SLEEP_FLAG -eq 0 ]] && sleep 1
		for url in $urls; do 
			ms=""
			message=""
			file_ping_data=$(getWordsAndNumbers "$url")	
			icmp_seq=${icmp_seq_array["$file_ping_data"]}
			ms_sum=${ms_sum_array["$file_ping_data"]}

			grep -E "^.*seq=$icmp_seq" "./.temp_$file_ping_data" \
				| grep -q "time"

			there_isnt_time=$?

			[[ $there_isnt_time -eq 0 ]] && ms=$(grep -E \
			"^.*seq=$icmp_seq" ./.temp_$file_ping_data \
			| sed -r 's/^.*time=|ms| +//g')

			[[ -z "$ms" ]] && ms=0

			ms_sum_array["$file_ping_data"]=$(python3 -c\
				"print('{:.2f}'.format($ms + $ms_sum))")
			ms_avg_array["$file_ping_data"]=$(python3 -c\
				"print('{:.2f}'.format($ms_sum/$icmp_seq, 2))")

	
			message="$url ${ms_avg_array["$file_ping_data"]}ms"			
			[[ "$ms" = "0" ]] && message="$url ..."
			
			# Clean line
			tput cup ${tput_line_position_array["$file_ping_data"]} 0
			echo "$url                                                     "

			# Show message
			tput cup ${tput_line_position_array["$file_ping_data"]} 0
			echo "$message"

			((icmp_seq_array["$file_ping_data"]++))
		done
	done &
	while_pid=$!

	tput cup $(tput lines) $(($(tput cols) - ${#quit_message}))
	echo $quit_message

	while :; do
		read -n 1 -s input
		

		if [[ "$input" = "$stop_flag" ]]; then
			killProccess $while_pid ${ping_pids_array[@]}

			for url in $urls; do
				file_ping_data=$(getWordsAndNumbers "$url")

				rm -rf "./.temp_$file_ping_data"
			done
			break
		fi
	done
	tput cnorm	
}

function screen() {
	local quit=0
	local option=
	local menu_options="$(cat <<- EOF
	1 "Start ping"
	2 "Manage hosts"
	EOF
	)"

	while :; do
		option=$(dialog_box title="$box_title" menu menu_options="$menu_options")
		quit=$?

		[[ $quit -ne 0 ]] && return $quit

		case $option in
			1)
				tput clear
				doPing $URLS
				tput clear
			;;
			2) hosts_manager;;
		esac
	done
}

# --------------------------------------------------------
#
# Execution ----------------------------------------------

if [[ -n "$*" ]]; then
	for url in $*; do
		grep -E -q "^.*\-" <<< $url
		isnt_option=$?

		if [[ $isnt_option -eq 0 ]]; then
			case $url in
				-h) help_menu && exit $SUCCESS_EXIT_CODE;;
				-mg) hosts_manager && exit $SUCCESS_EXITCODE;;
				--no-sleep) NO_SLEEP_FLAG=1 && continue;;
				*) continue;;
			esac
		fi

		# There's not in urls?
		grep -q "$url" <<< $URLS
		[[ $? -ne 0 ]] && URLS="$URLS $url"
	done
fi

tput clear
screen
tput clear
# --------------------------------------------------------
