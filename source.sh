# This is an internet download manager that release with gnu public licence.
# you can redistribute it for your self.
# Auther: M3

crntDir=$(pwd)	# save important files in this directory. you can change it for yourself.
path=$crntDir
username="@@"
password="@@"
proxy=""
setTorrent="NULL"

function getLinks {
	num=0
	printf "Type the link: "
		read link
	printf "Type path(current path is default): "
		read path
	if [[ $path == "" ]];then path=$crntDir ; fi
	
	while [[ $num -ne 5 ]]
	do
		printf "options:\n"
		printf "\t1- username and password (warnning: password will be save as clear text)\n"
		printf "\t2- proxy\n"	#http || https || ftp
		printf "\t3- torrent(set link as torrent)\n"
		printf "\t4- save\n"
		printf "\t5- exit(save nothing even entered link)\n"
		printf "Enter : "
			read num
		if [[ $num == 5 ]]; then
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
					#http - https - ftp
					clear	# clear screen
					printf "Info:\tExample: \"http|https|ftp://username:password@proxy:PORT\"\n"
					printf "Warn:\tPassword will be save as clear text\n"
					printf "type: "
						read proxy
				;;
				3)
					setTorrent=1	# i don't want to begin seed after download completed.
				;;
				4)
					#counter=0
					counter=$(cat $crntDir/links.txt 2>$crntDir/error.txt | wc -l)
					((counter++))
					echo "$counter $link $path" >> $crntDir/links.txt
					if [[ ( $username -ne "" && $password -ne "" ) || $setTorrent -ne "NULL" ]];then
						printf "$counter $username\t$password\t$setTorrent\n" >> $crntDir/req.txt
					fi
					if [[ $proxy -ne "" ]]; then
						printf "$counter $proxy" >> $crntDir/prx.txt
					fi
					break
				;;
				5) return
				;;
				
				*) echo "Are you sick? :)"
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

if [[ $1 != "start" ]];then
	
	while true; do
		ch=""
		printf "Do you want to put a link in file?(y=default/n) "
			read ch

		if [[ $ch == 'y' || $ch == "" ]];then
			getLinks
			clear
		elif [[ $ch == 'n' ]];then
			printf "Do you want to start download?(y / n=exit) "
				read ch
			if [[ $ch != 'y' ]]; then echo exit ; exit ; fi
		else
			printf "Are you crazy? :)\n"
			exit
		fi
	done
fi


while read link; do

	options=""
	
	counter=$(echo $link | awk '{print $1}')

	path=$(echo $link | awk '{print $3}')	# get path of download
	link=$(echo $link | awk '{print $2}')	# set link to be download

	info=$(cat $crntDir/req.txt 2>$crntDir/error.txt | grep -E "^$counter" | cut -d' ' -f2-) # fetch requirment information like usernname,passowrd,... from req.txt
	proxy=$(cat $crntDir/prx.txt 2>$crntDir/error.txt | grep -E "^$counter" | cut -d' ' -f2-) # fetch proxy informations from prx.txt file.
	
	if [[ $info != "" ]];then
		username=$(echo $info | awk '{print $2}')
		password=$(echo $info | awk '{print $3}')
		torrent=$(echo $info | awk '{print $4}')
	fi
	
	if [[ $username != "@@" && $passowrd != "@@" ]]; then	options="--http-user=$username  --http-passwd=$password" ; fi
	if [[ $proxy != "" && $options -eq " " ]]; then	options="$proxy"  ; fi
	if [[ $torrent -ne "NULL" ]]; then	options="$options  --seed-time=0" ; fi

	
	aria2c -x16 -s16 -k 1M  $options -d "${path}" --log-level=notice -l dllog "${link}"
	
	# delete link and it's options from files if download was successfull.
	if [[ $? == 0 ]];then
		sed -r -i "/^$counter/d" "$crntDir/links.txt" "$crntDir/req.txt"  "$crntDir/prx.txt"  2>$crntDir/error.txt
	fi
	
done < links.txt	# links.txt contains links should be download.
