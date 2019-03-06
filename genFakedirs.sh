#!/bin/bash
# Creates a number of directories, with a number of dummy files in 
# Usage: genFakedirs [Number of Dirs] [Number of files per dir] [chars per file]

##################################################################################
# FUNCTIONS
##################################################################################

function genRandomText() {
	local n=$1
	while [ $((n--)) -gt 0 ]
	do
		printf "\x$(printf %x $((RANDOM % 26 + 65)))"
	done
echo
}

function printHr() {
	for ((i=0; i<$(tput cols); i++)) 
	do 
		echo -e "=\c"
	done
}

function askYesNo() {
	read -p "$1 ([y]es or [n]o)?: "
	case $(echo $REPLY | tr '[A-Z]' '[a-z]') in
		y|yes) ;;
		*) echo "Exiting..."
			exit 0
			;;
	esac
}

##################################################################################
# Main code
##################################################################################

if [[ $# -ne 3 ]]; then
	printHr
	echo "You need to provide options."
	echo "Usage: genFakedirs [Number of Dirs] [Number of files per dir] [chars per file]"
	printHr
	exit 0
fi


numDirs=$1
numFiles=$2
numChars=$3

printHr
echo "This will create $numDirs directories."
echo "Each directory will contain $numFiles files."
echo "Each file will contain $numChars characters"
echo "Do you wish to continue" 
askYesNo
printHr
echo "Percent complete"
count=0
for ((i=0;i<$numDirs;i++))
do
	dirName=$(shuf -n 2 /usr/share/dict/words |  sed 'N;s/\n/_/' | sed "s/'//g")
	mkdir  $dirName
	cd $dirName

	for ((j=0;j<$numFiles;j++))
	do 

		fileName=$(shuf -n 2 /usr/share/dict/words | sed 'N;s/\n/_/' | sed "s/'//g")       
		touch $fileName
		genRandomText $numChars > $fileName
	done
	cd ..
	count=$((count + 1))
	percentComplete=$(echo "scale=1;100 * ( $count / $numDirs )" | bc -l)
	echo $percentComplete"%"


done
echo "Done....."
