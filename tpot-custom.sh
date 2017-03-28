#!/bin/bash

echo "Usage: $0 [ -s Setup ]"

sudo modprobe -r bluetooth
sudo modprobe -r mac_hid

if [ "$1" = "-s" ]; then

	sudo apt install nano
	sudo apt install dnsutils
	sudo apt install iputils-tracepath
	#sudo apt install iputils-arping
	sudo apt install secure-delete

	read -rsp $'Press [Enter] to continue or [Ctrl + C] to exit!\n'

	sudo apt install -y snapd
	# enable the snapd systemd service
	#sudo systemctl enable --now snapd.socket

	sudo snap install canonical-livepatch

	sudo apt install unattended-upgrades
	sudo dpkg-reconfigure unattended-upgrades

fi

function splitter {
	echo '--------------------------------'
}

function title {
	printf "\e[7m%-`tput cols`s\e[0m\n" "$1"
}

# Test an IP address for validity:
# Usage:
#      valid_ip IP_ADDRESS
#      if [[ $? -eq 0 ]]; then echo good; else echo bad; fi
#   OR
#      if valid_ip IP_ADDRESS; then echo good; else echo bad; fi
#
function valid_ip() {
	local ip=$1
	local stat=1

	if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
		OIFS=$IFS
		IFS='.'
		ip=($ip)
		IFS=$OIFS
		[[ ${ip[0]} -le 255 && ${ip[1]} -le 255 && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
		stat=$?
	fi
	return $stat
}

splitter
echo 'Useful custom commands for T-Pot (client)'
echo 'Usage: '$0''
echo ' '
echo 'update       - Ubuntu update / upgrade'
echo 'time         - Set the time of now'
echo 'repair       - Repair apt'
echo 'reconfigure  - Reconfigure Debian packet manager'
echo 'network      - Network informations'
echo 'iptables     - List iptables'
echo 'ipblock      - Quick ip address blocking'
echo 'flush        - Flush ip / Clean dns'
echo 'bash-history - Search in .bash_history file'
echo 'scripthost   - Create virtual host for apache (server)'
echo 'download     - Download the latest of this script'
echo 'livepatch    - Canonical livepatch'
echo 'blocklist    - Internal temporary ip range blocking'
echo 'docker       - Docker info / Remove old containers and images'
echo 'quit         - Exit script'
splitter

OPTIONS="update time repair reconfigure network iptables ipblock flush bash-history download livepatch blocklist docker quit"
select opt in $OPTIONS; do
	if [ "$opt" = "quit" ]; then
		clear
		exit

	elif [ "$opt" = "update" ]; then

		sudo dpkg --configure -a
		sudo apt-get autoclean
		sudo apt-get autoremove
		sudo apt-get check
		sudo apt-get -f install # -f = --fix-broken
		sudo apt-get update
		sudo apt-get upgrade

		#sudo dpkg -S docker | awk '{print $1}' | cut -d':' -f1 | sort -u
		sudo apt-get upgrade docker
		sudo apt-get upgrade docker-engine

	elif [ "$opt" = "time" ]; then

		sudo service ntp restart
		echo "Please wait ..."
		sleep 7
		ntptime -c

		echo "Do you like to set the time to the bios? [ y | n ]"
		read yorn
		if [ "$yorn" = "y" ]; then
			sudo hwclock -r # --utc
			sudo hwclock -w --localtime # --utc
			echo ""
			sudo hwclock -r # --utc
		fi

	elif [ "$opt" = "repair" ]; then

		NOW=$(date +"%y-%m-%d_%H-%M-%S")
		sudo apt-get clean
		sudo mv /var/lib/apt/lists /var/lib/apt/lists_$NOW
		sudo mkdir -p /var/lib/apt/lists/partial
		sudo rm -rf /var/lib/apt/lists/*
		sudo apt-get clean
		sudo apt-get check
		sudo apt-get update
		echo "Do you like to delete the old apt lists?"
		read -rsp $'Press [Enter] to continue or [Ctrl + C] to exit!\n'
		sudo rm -rf  /var/lib/apt/lists_$NOW

	elif [ "$opt" = "reconfigure" ]; then

		sudo dpkg-reconfigure debconf
		for pkg in $(dpkg-query --show | awk '{print $1}'); do echo "$pkg" ; sudo dpkg-reconfigure --frontend=noninteractive --priority=critical $pkg < /dev/null ; done

	elif [ "$opt" = "network" ]; then

		#myexip=`wget -q -O - "http://myip.dnsomatic.com/"`
		myexip2=`wget -q -O - "http://myexternalip.com/raw"`
		#echo "IP (myip.dnsomatic.com): $myexip"
		#echo "IP (myexternalip.com): $myexip2"
		ipt1=`echo $myexip2 | cut -d'.' -f1`
		ipt2=`echo $myexip2 | cut -d'.' -f2`
		ipt3=`echo $myexip2 | cut -d'.' -f3`
		#ipgateway="$ipt1.$ipt2.$ipt3.1"
		ipgateway=`tracepath -b -n -m 2 community.sicherheitstacho.eu | grep 2\: | awk '{print $2}' | tail -1`

		dig @$myexip2 +trace community.sicherheitstacho.eu
		splitter
		dig 4.2.2.1 +trace $myexip2
		splitter
		dig @192.168.178.1 +trace community.sicherheitstacho.eu
		splitter
		dig @192.168.178.1 +trace apt.dockerproject.org
		splitter

		#sudo ifconfig -a | less
		sudo netstat -atuWp | less
		read -rsp $'Press [Enter] to continue or [Ctrl + C] to exit!\n'

		title "Command: route -n"
		sudo route -n
		title "Command: ip route show"
		sudo ip route show
		title "Command: ip route show cache"
		sudo ip route show cache

		read -rsp $'Press [Enter] to continue or [Ctrl + C] to exit!\n'

		title "Command: ip route show table local"
		sudo ip route show table local
		title "Command: ip route show table main"
		sudo ip route show table main
		title "Command: ip route show table default"
		sudo ip route show table default
		title "Command: ip route show table unspec"
		sudo ip route show table unspec

		read -rsp $'Press [Enter] to continue or [Ctrl + C] to exit!\n'

		title "Command: ip -s route get ..."
		sudo ip -s route get 127.0.0.1/32
		splitter
		sudo ip -s route get $myexip2
		splitter
		sudo ip -s route get $ipgateway
		splitter
		sudo ip -s route get 192.168.178.1
		splitter
		sudo ip -s route get 192.168.178.24

	elif [ "$opt" = "iptables" ]; then

		sudo iptables -S && sudo ip6tables -S | less
		sudo iptables -L && sudo ip6tables -L | less

	elif [ "$opt" = "ipblock" ]; then

		#TODO: Currently only for IPv4
		echo 'Please enter an ip4 address!'
		read ip4
		if [ "$ip4" = "" ]; then
			echo "Please enter an valid ip address!"
			break
		else
			#if valid_ip IP_ADDRESS; then
				sudo iptables -I INPUT -s $ip4 -j DROP
				sudo iptables -I OUTPUT -s $ip4 -j DROP
				sudo iptables -I FORWARD -s $ip4 -j DROP

				sudo iptables-save
			#else
			#	echo "This is not an valid ip4 address!"
			#fi
		fi

	elif [ "$opt" = "flush" ]; then

		#sudo service dns-clean stop
		#sudo service dns-clean start
		#sudo systemctl restart systemd-resolved.service
		#sudo systemctl restart systemd-networkd.service
		sudo /etc/init.d/dns-clean restart
		sudo ip -s -s neigh flush all
		sudo ip -6 -s -s neigh flush all

		sudo ip route flush cache
		sudo ip -6 route flush cache
		#sudo ip -6 route flush table local
		#sudo ip -6 route flush table main
		#sudo ip -6 route flush table default
		#sudo ip -6 route flush table unspec

	elif [ "$opt" = "bash-history" ]; then

		echo "Please enter your search term!"
		read st
		if [ "$st" != "" ]; then cat ~/.bash_history | grep $st ; fi

		read -rsp $'Press [Enter] to continue or [Ctrl + C] to exit!\n'

		cat ~/.bash_history | less

	elif [ "$opt" = "download" ]; then

		#cd $HOME
		#git clone https://github.com/exesdotnet/useful.git
		#cd $HOME/useful
		#git branch
		#git checkout master

		wget https://raw.githubusercontent.com/exesdotnet/useful/master/tpot-custom.sh -O ~/tpot-custom.sh.txt

		mv ~/tpot-custom.sh.txt ~/tpot-custom.sh

		chmod u+x ~/tpot-custom.sh

		exit

	elif [ "$opt" = "livepatch" ]; then

		echo "Please enter the livepatch id!"
		read lpid
		if [ "$lpid" != "" ]; then echo "$lpid" > ~lpid.txt ; fi

		sudo canonical-livepatch disable `cat ~lpid.txt`
		sudo canonical-livepatch enable `cat ~lpid.txt`
		canonical-livepatch status --verbose

		lsmod | grep livepatch

		sudo canonical-livepatch disable `cat ~lpid.txt`

	elif [ "$opt" = "blocklist" ]; then

		# Just for testing ;)
		echo "1.54.176.0/20
1.56.0.0/13
5.45.64.0/21
5.45.64.0/21
5.45.72.0/22
5.45.76.0/22
5.45.84.0/22
42.62.0.0/17
46.174.184.0/21
79.64.0.0/12
87.0.0.0/12
91.195.102.0/23
94.102.52.0/22
120.56.0.0/13
121.160.0.0/11
169.54.244.64/27
181.24.0.0/14
188.18.64.0/19
194.88.104.0/22
195.22.124.0/22
210.14.32.0/20
221.224.0.0/13" > ~/tmp-iprangelist.txt

		OLDIFS=$IFS
		IFS=$'\n'
		iprl=($(cat ~/tmp-iprangelist.txt))
		IFS=$OLDIFS
		iLen=${#iprl[@]}
		for (( i=0; i<${iLen}; i++ )); do
			echo "${iprl[$i]}"
			sudo iptables -I INPUT -s "${iprl[$i]}" -j DROP
			sudo iptables -I OUTPUT -s "${iprl[$i]}" -j DROP
			sudo iptables -I FORWARD -s "${iprl[$i]}" -j DROP
		done

		rm ~/tmp-iprangelist.txt

	elif [ "$opt" = "docker" ]; then

		sudo docker ps -a
		sudo docker images | sort
		sudo docker network ls | sort

		echo "Do you like to remove old docker containers and images?"
		read -rsp $'Press [Enter] to continue or [Ctrl + C] to exit!\n'

		# Remove old docker containers
		#sudo docker ps -a | grep 'weeks ago' | awk '{print $1}' | xargs --no-run-if-empty sudo docker rm -f
		sudo docker rm $(sudo docker ps -q -f status=exited)
		# Remove old images
		sudo docker rmi $(sudo docker images -q -f dangling=true)

	else
		echo 'Wrong option'
		echo '1) update'
		echo '2) time'
		echo '3) repair'
		echo '4) reconfigure'
		echo '5) network'
		echo '6) iptables'
		echo '7) ipblock'
		echo '8) flush'
		echo '9) bash-history'
		echo '10) download'
		echo '11) livepatch'
		echo '12) blocklist'
		echo '13) docker'
		echo '14) quit'
	fi
done
