#!/bin/bash

function error_exit() {
	echo "$1" 1>&2
	exit 1
}

if [ -d ~/useful ]; then
	rm -Rf ~/useful
fi

cd $HOME
git clone https://github.com/exesdotnet/useful.git
cd $HOME/useful
#git branch
#git checkout master

#wget https://raw.githubusercontent.com/exesdotnet/useful/master/unpack-scripts.sh -O ~/unpack-scripts.sh
#wget https://raw.githubusercontent.com/exesdotnet/useful/master/scripts.tgz.cry -O ~/scripts.tgz.cry

if [ ! -f "~/unpack-scripts.sh" ]; then
	chmod 750 ~/useful/unpack-scripts.sh
	#~/useful/unpack-scripts.sh
fi

cp ~/useful/unpack-scripts.sh ~/unpack-scripts.sh
cp ~/useful/scripts.tgz.cry ~/scripts.tgz.cry

cd $HOME

if openssl enc -aes-256-cbc -md sha512 -pbkdf2 -iter 1000 -salt -d -in ~/scripts.tgz.cry -out ~/scripts.tgz ; then
#if openssl aes-256-cbc -d -a -in ~/scripts.tgz.cry -out ~/scripts.tgz ; then
	echo "[ Decryption is fine! ]"
else
	error_exit "[ Error occured! Aborting. ]"
fi

tar -xvzf ~/scripts.tgz

rm ~/scripts.tgz.cry
rm ~/scripts.tgz

chmod 770 ~/*.sh
chmod 640 ~/*.txt

cp ~/tpot-custom.sh ~/tpot-custom.sh.bak

echo ""
echo "Later remove the scripts with command 'sudo rm -f *.sh; rm -f *.log; rm -f ~/resizer-windows.txt; rm -f  ~/3rd.txt'!"
echo "Additionally execute 'mv ~/tpot-custom.sh.bak ~/tpot-custom.sh'!"
echo ""

