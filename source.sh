# This is an internet download manager that release with gnu public licence.
# you can redistribute it for your self.
# Auther: M3

#*************************************START******************************************
crntDir=$(pwd)	# save important files(links.txt,dllog,error.txt,...) in this directory. you can change it for yourself.
path=$crntDir	# save downloaded link in this direcory. default is current directory, you can change it durring the start program.
username="@@"	# you can't have @@ username
password="@@"	# you can't have @@ password
proxy=""
setTorrent="T_NULL"	# default initialization
setYoutube="Y_NULL"	# default initialization
#setFtp="F_NULL"
#*************************************FINISH******************************************

#*************************************START******************************************
function getLinks {
	num=0
	printf "Type the link: "
		read link
	printf "Type path(The current directory is default): "
		read path
	if [[ $path == "" ]];then path=$crntDir ; fi
	
	while [[ $num -ne 5 ]]
	do
		printf "options:\n"
		printf "\t1- username and password (warnning: password will be save as clear text)\n"
		printf "\t2- proxy\n"	#http || https || ftp
		printf "\t3- torrent(set link as torrent)\n"
		printf "\t4- youtube\n"
		printf "\t5- save\n"
		printf "\t6- exit(save nothing even entered link)\n"
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
					setTorrent="1t"	# i don't want to begin seed after download completed.
				;;
				4)
					echo "We assume you have been filltering with your goverment and don't access to the some of sites like youtube."
					echo "To downloading from same sites we used youtube-dl and tor.(man tor - man youtube-dl)"
					echo "Please start tor service when you prepare to download."
					echo "hit 'ENTER'" ; read hit
					
					setYoutube="1y"
				;;
				5)
					counter=$(cat $crntDir/links.txt 2>>$crntDir/error.txt | tail -1 | awk '{print $1}')		# fixed
					((counter++))
					echo "$counter $link $path" >> $crntDir/links.txt
					if [[ ( $username -ne "@@" && $password -ne "@@" ) || $setTorrent -ne "T_NULL" ]];then
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
		printf "torrent:\t"  ; if [[ $setTorrent -eq 1 ]]; then echo "True"; else echo "False" ; fi
		printf "proxy:\t"    ; echo $proxy
		printf "*********************************************************\n"
	done

}
#*************************************FINISH*****************************************

#*************************************START******************************************
#start program!
if [[ $1 != "start" ]];then	# you can start downloading with give "start" arguman to execute program. like "./idm.sh start"
	
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
# check internet connection. if it was diactived, stop downloading while connection active.
function checkNet {
	stime=0
	counter=1
	while true;do
		if [[ `ping -c 4 8.8.8.8 &>/dev/null ; echo $?` != 0 ]];then
			echo "$counter tries to connect to internet but failed" >> $crntDir/error.txt
			if [[ $counter == 10 ]];then
				echo "the connection is failed..." >> dllog
				exit	# exit the program and stop downloads.
			fi
			
			let stime=$stime+30
			$(nmcli nm wifi off)	# this may be different on your system
			sleep $stime
			$(nmcli nm wifi on)	# this may be different on your system
			sleep 20
		else
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

	path=$(echo $link | awk '{print $3}')	# get path of download
	link=$(echo $link | awk '{print $2}')	# set link to be download

	info=$(cat $crntDir/req.txt 2>>$crntDir/error.txt | grep -E "^$counter" | cut -d' ' -f2-) # fetch requirment information like usernname,passowrd,... from req.txt
	proxy=$(cat $crntDir/prx.txt 2>>$crntDir/error.txt | grep -E "^$counter" | cut -d' ' -f2-) # fetch proxy informations from prx.txt file.
	
	if [[ $info != "" ]];then
		username=$(echo $info | awk '{print $2}')
		password=$(echo $info | awk '{print $3}')
		torrent=$(echo $info | awk '{print $4}')
		youtube=$(echo $info | awk '{print $5}')
	fi
	
	if [[ $username != "@@" && $passowrd != "@@" ]]; then	options="--http-user=$username  --http-passwd=$password" ; fi

	if [[ $proxy != "" && $options -eq " " ]]; then	options="--all-proxy=$proxy"  ; fi

	if [[ $torrent == "1t" ]]; then options="$options  --seed-time=0" ; fi

	if [[ $youtube == "1y" ]];then
		# Download from youtube with youtube-dl. not used aria2c
		echo "later..."
	else
		aria2c -x16 -s16 -j1 -k 1M  $options -d "${path}" --log-level=notice -l dllog "${link}"
	fi
	
	# delete link and it's options from files if download was successfull.
	if [[ $? == 0 ]];then
		sed -r -i "/^$counter/d" "$crntDir/links.txt" "$crntDir/req.txt"  "$crntDir/prx.txt"  2>>$crntDir/error.txt
	fi
	
done < links.txt	# links.txt contains links that should be download.(main file)
#*************************************FINISH*****************************************
