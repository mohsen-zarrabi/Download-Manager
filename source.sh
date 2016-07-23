#!/bin/bash

# Auther: M3

#*********************************Start Initialization*******************************
# Initialization
crntDir="/path/to/download/files"	# save important files in this directory like links file, proxy file, etc. you can/should change it for yourself.	# fixed
path=$crntDir	# default path to save downloads. you can save optional link in diffrent path to douring the program.
username="@@"	# default username, you don not have @@ as real username
password="@@"	# default passowrd, you do not have @@ as real password
proxy=""
setTorrent="T_NULL"
setYoutube="Y_NULL"

#*********************************Finish Initialization******************************

#*************************************START******************************************
function getLinks {
	num=0
	printf "Type the link: "
		read link

	link=$(echo "$link" | sed  's/ /\\ /g')	 # escape all of space in link
	link="#$link#"
	
	printf "Type path(The current directory is default): "
		read path
	if [[ $path == "" ]];then path=$crntDir ; fi
	
	while [[ $num -ne 6 ]]
	do
		printf "options:\n"
		printf "\t1- username and password (warnning: password will be save as clear text)\n"
		printf "\t2- proxy\n"	#http || https || ftp
		printf "\t3- torrent(set link as torrent)\n"
		printf "\t4- youtube\n"
		printf "\t5- save\n"
		printf "\t6- exit(nothing save even entered link)\n"
		printf "Enter : "
			read num
		if [[ $num == 6 ]]; then
			return
		fi
			
			case "$num" in
				1)
					#getUsernamePass
					printf "Enter username: "
						read username
					printf "Enter passowrd: "
						read password
				;;
				2)	
					clear	# clear screen
					printf "Info:\tType the require options like it \"http|https|ftp://username:password@proxy:PORT\"\n"
					printf "Warn:\tPassword will be save as clear text\n"
					printf "type: "
						read proxy
				;;
				3)
					setTorrent="1t"
				;;
				4)
					echo "We assume you have been filter with your goverment and don't access to the some of sites like youtube."
					echo "To downloading from same sites we used youtube-dl and tor.(man tor - man youtube-dl)"
					echo "Please start tor service when you prepare to download."
					echo "hit 'ENTER'" ; read hit
					
					setYoutube="1y"
				;;
				5)
					counter=$(cat $crntDir/links.txt 2>>$crntDir/error.txt | tail -1 | awk '{print $1}')
					((counter++))
					echo "$counter $link $path" >> $crntDir/links.txt
					
					if [[ ( $username -ne "@@" && $password -ne "@@" ) || "$setTorrent" == "1t" ]];then
						printf "$counter $username\t$password\t$setTorrent\t$setYoutube\n" >> $crntDir/req.txt
					fi
					
					if [[ $proxy -ne "" ]]; then
						printf "$counter $proxy" >> $crntDir/prx.txt
					fi

					break
				;;
				6) return
				;;
			esac
		clear
		printf "*********************************************************\n"
		printf "Link: "      ; echo $link
		printf "username:\t" ; echo $username
		printf "passowrd:\t" ; echo $password
		printf "torrent:\t"  ; if [[ "$setTorrent" == "1t" ]]; then echo "True"; else echo "False" ; fi
		printf "proxy:\t"    ; echo $proxy
		printf "*********************************************************\n"
	done

}
#*************************************FINISH*****************************************

#*************************************START******************************************
#start program!
if [[ "$1" != "start" ]];then
	
	while true; do
		ch=""
		printf "Do you want to put a link in file?(y=default/n) "
			read ch

		if [[ $ch == 'y' || $ch == "" ]];then
			getLinks	# getLinks is a function
			clear		# clear the screen
		elif [[ $ch == 'n' ]];then
			printf "Do you want to start download?(y / n=exit) "
				read ch
			if [[ $ch != 'y' ]]; then echo exit ; exit ; fi
			break
		else
			printf "have a nice day ;)\n"
			exit
		fi
	done
fi
#*************************************FINISH*****************************************

#*************************************START******************************************
function checkNet {
	stime=0
	counter=1	# the number of attemps to connect to the internet. default is 10.
	while true;do
		if [[ `ping -c 4 8.8.8.8 &>/dev/null ; echo $?` != 0 ]];then
			#echo $counter
			echo -e "$(date +%F"  "%T)\t#$counter tries to connect to internet but failed" >> $crntDir/error.txt
			if [[ $counter == 10 ]];then
				echo "the connection is failed..." >> dllog
				exit	# close the program
			fi
			
			let stime=$stime+30
			$(nmcli nm wifi off)
			sleep $stime
			$(nmcli nm wifi on)
			sleep 20
		else
			echo "************************************"
			echo "**   The internet is connected    **"
			echo "**     Enjoy of downloading...    **"
			echo "************************************"
			
			return
		fi
		let counter=$counter+1
	done
}
#*************************************FINISH*****************************************

#*************************************START******************************************
#start downloading!
while read link; do

	checkNet	# function

	options=""
	
	counter=$(echo $link | awk '{print $1}')
	path=$(echo $link | cut -d# -f3)	# get path of download , fixed
	link=$(echo $link | cut -d# -f2)	# set link to be download, fixed

	info=$(cat $crntDir/req.txt 2>>$crntDir/error.txt | grep -E "^$counter" | cut -d' ' -f2-) # fetch requirment information like usernname,passowrd,... from req.txt
	proxy=$(cat $crntDir/prx.txt 2>>$crntDir/error.txt | grep -E "^$counter" | cut -d' ' -f2-) # fetch proxy informations from prx.txt file.
	
	if [[ "$info" != "" ]];then
		username=$(echo $info | awk '{print $1}')
		password=$(echo $info | awk '{print $2}')
		torrent=$(echo $info | awk '{print $3}')
		youtube=$(echo $info | awk '{print $4}')
	fi
	
	# set require and optional options
	if [[ "$username" != "@@" && "$passowrd" != "@@" ]]; then	options="--http-user=$username  --http-passwd=$password" ; fi

	if [[ "$proxy" != "" && $options -eq " " ]]; then	options="--all-proxy=$proxy"  ; fi

	if [[ "$torrent" == "1t" ]]; then options="$options  --seed-time=0" ; fi

	cnt_down=0	# the number of attemps to download link
	while [[ $cnt_down -ne 2 ]]
	do
		if [[ "$youtube" == "1y" ]];then
		# Download from youtube with youtube-dl. not used aria2c
		# we should be check that tor is run or not in this section. may be we need to change route with '-HUP' or another operations like reset tor and etc.
			echo "youtube"
		elif [[ "$torrent" == "1t" ]];then
			# it's different. because we must set that where is the torrent file to download be successfull
			aria2c -x16 -s16 -j1 -k 1M  $options -d "${path}" --log-level=notice -l "$crntDir/dllog" "$crntDir/${link}"
		else
			aria2c -x16 -s16 -j1 -k 1M  $options -d "${path}" --log-level=notice -l "$crntDir/dllog" "${link}"
		fi
		
		# delete link and it's options from files if download was successfully.
		if [[ $? == 0 ]];then
			sed -r -i "/^$counter/d" "$crntDir/links.txt" "$crntDir/req.txt"  "$crntDir/prx.txt"  2>>$crntDir/error.txt
			break
		else
			checkNet	# function
			let cnt_down=$cnt_down+1
		fi
	done
	
done < $crntDir/links.txt
#*************************************FINISH*****************************************
