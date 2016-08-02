#!/bin/bash

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
echo 'download     - Download the latest of this script'
echo 'blacklist    - Export and upload the blacklisted ip addresses'
echo 'quit         - Exit script'
splitter

OPTIONS="update time repair reconfigure network iptables ipblock flush bash-history download blacklist quit"
select opt in $OPTIONS; do
	if [ "$opt" = "quit" ]; then
		clear
		exit

	elif [ "$opt" = "update" ]; then

		sudo launchpad-getkeys
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
		ipgateway="$ipt1.$ipt2.$ipt3.1"

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
		title "---- Command: ip route show table main"
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

	elif [ "$opt" = "blacklist" ]; then

		#TODO: Export and upload blacklist
		echo "[ TODO: Export and upload blacklist ]"

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
		echo '11) blacklist'
		echo '12) quit'
	fi
done
