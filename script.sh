#!/usr/bin/env bash
# bash version: 5.0.17

# DEV: @josafaverissimo, josafaverissimo98@gmail.com

tput clear

# initiate a ping to www.google.com and save the proccess id

function doPing() {
	#Parameters url:$1
	url=$1

	filename_temp=`grep -oP '[a-zA-Z]' <<< $url | tr -d '\n'`
	ping_temp_file="./.temp_$filename_temp"

	# create temporary file data
	>$ping_temp_file
	
	#initiate ping in background
	ping $url > $ping_temp_file &
	PING_PID=$!

	icmp_seq=1
	time_field=8
	ms_field=2

	ms_sum=0
	ms_avg=0

	tput cup 0 0
	echo $url

	while :; do
		sleep 1
	
		# get ms from ping
		ms=`grep seq=$icmp_seq $ping_temp_file | head -n 1 | cut -d ' ' -f $time_field | cut -d'=' -f $ms_field`
		
		if [ ! -z "$ms" ]; then
			$((++icmp_seq)) 2> /dev/null
			ms_sum=`python -c "print('{:.2f}'.format($ms + $ms_sum))"`
			ms_avg=`python -c "print('{:.2f}'.format($ms_sum/$icmp_seq, 2))"`
		fi
		
		tput cup 0 20
		echo "$ms_avg""ms"
	done
}

doPing "www.microsoft.com"

