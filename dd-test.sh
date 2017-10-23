#!/bin/bash -l

set -eu

echo $@ 
if [[ $# -le 1 ]]; then
	echo -e "*** ERROR ***\n"
	echo -e "\nUSAGE: Please provide the following arguements: "
	echo -e "dd-test.sh <BLOCKSIZE> <BLOCKCOUNT> "
	echo -e "For example:\n "
	echo -e "dd-test.sh 1M 500 \n "
	exit 2
fi

echo Running on $HOSTNAME
BLOCKSIZE=$1
BLOCKCOUNT=$2

TESTDIR=/data/dd-test

mkdir -p $TESTDIR
cd $TESTDIR

testfile=test.$(hostname).$$

echo "Testing in $PWD using filename $testfile"

logfile=dd.$$.log

echo $(date +"%Y-%m-%d,%H%M%S") Running dd

dd if=/dev/zero of=$testfile bs=$BLOCKSIZE count=$BLOCKCOUNT conv=fdatasync 2>&1 | tee $logfile

echo $(date +"%Y-%m-%d,%H%M%S") Finished dd

rm $testfile

if grep -q "GB/s" $logfile; then
		rate=$(grep "GB/s" $logfile | sed 's# GB/s$##'| sed 's#^.* s, ##')
		rate=$(echo "$rate*1000" | bc)
	else
		rate=$(grep "MB/s" $logfile | sed 's# MB/s$##'| sed 's#^.* s, ##')
fi

rm $logfile

# Append to csv file in the following format
# Date, Time, Blocksize, Blockcount, Rate, Hostname
echo $(date +"%Y-%m-%d,%H%M%S"),$rate,$HOSTNAME  >> dd-rate.$HOSTNAME.csv
	
echo $(date +"%Y-%m-%d,%H%M%S") Done

