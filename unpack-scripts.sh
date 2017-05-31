#!/bin/bash

cd $HOME
git clone https://github.com/exesdotnet/useful.git
cd $HOME/useful
#git branch
#git checkout master

#wget https://raw.githubusercontent.com/exesdotnet/useful/master/unpack-scripts.sh -O ~/unpack-scripts.sh
#wget https://raw.githubusercontent.com/exesdotnet/useful/master/scripts.tgz.cry -O ~/scripts.tgz.cry

#chmod u+x ~/useful/unpack-scripts.sh
#~/useful/unpack-scripts.sh

cp ~/useful/unpack-scripts.sh ~/unpack-scripts.sh
cp ~/useful/scripts.tgz.cry ~/scripts.tgz.cry

cd $HOME

if openssl aes-256-cbc -d -a -in ~/scripts.tgz.cry -out ~/scripts.tgz ; then
	echo "[ Decryption is fine! ]"
else
	error_exit "[ Error occured! Aborting. ]"
fi

tar -xvzf ~/scripts.tgz

rm ~/scripts.tgz.cry
rm ~/scripts.tgz

chmod ugo+x ~/*.sh

cp ~/tpot-custom.sh ~/tpot-custom.sh.bak

echo ""
echo "Later remove the scripts with command 'sudo rm -f *.sh'!"
echo "Additionally execute 'mv ~/tpot-custom.sh.bak ~/tpot-custom.sh'!"
echo ""

