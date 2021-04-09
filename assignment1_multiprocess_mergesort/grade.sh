#!/bin/bash

#######################################################################
#
# Copyright (C) 2020-2021 David C. Harrison. All right reserved.
#
# You may not use, distribute, publish, or modify this code without 
# the express written permission of the copyright holder.
#
#######################################################################

echo ""
echo "CSE130 Assignment 1"
echo ""
date

ptc=`grep pthread_ *.c | wc -l`
if (( ptc > 0 ))
then
  echo "ERROR: pthreads detected"
  exit
fi

total=0
function check() {
  ./check.sh $1 | tee check.out

  ptotal=0
  pcnt=0
  for pct in `cat check.out | grep 'Tests' | grep '\%' | sed 's/\%//' | awk -F "/" '{print $2}' | awk -F " " '{print $2}'`
  do
  ptotal=`echo "scale=2; $ptotal + $pct" | bc -l`
  (( pcnt += 1 ))
  done

  total=0;
  if (( pcnt > 0 ))
  then
  total=`echo "scale=2; ($ptotal / $pcnt) * 0.45" | bc -l`
  fi
  rm check.out
}

echo
echo "######### UNIX Shared Memory #############"
check usort
utotal=$total

echo
echo "######### POSIX Shared Memory #############"
check psort
ptotal=$total

total=`echo "scale=2; ($ptotal + $utotal)" | bc -l`

echo 
echo "######### GRADE ###########################"
echo 

printf "%20s:         %5.1f%% of 90%%\n" "Tests" $total

cat *make.out > make.out
ccode=0
cstr="yes"
valg=0
vstr="n/a"
if [ ! -s make.out ]
then
  (( ccode = 5 ))
  cstr="none"
  > valgrind.out
  flags="--track-origins=yes --leak-check=full --show-leak-kinds=all"
  valgrind $flags ./usort -m 32 1>/dev/null 2>>valgrind.out
  valgrind $flags ./posrt -m 32 1>/dev/null 2>>valgrind.out

  valg=`grep 'ERROR SUMMARY' valgrind.out | grep -v 'ERROR SUMMARY: 0' | \
    awk 'BEGIN {sum=0} {sum += $4} END { print sum }'`

  valw=`grep 'Warning: ' valgrind.out | wc -l`

  (( valg += valw ))
fi
printf "%20s:   %4s  %5.1f%% of  5%%\n" "Compiler Warnings" $cstr $ccode 

errors=0
if (( valg > 0 ))
then
  vstr="$valg"
fi

if (( ccode == 5 && valg == 0 ))
then
  (( errors = 5 ))
  vstr="none"
fi
printf "%20s:   %4s  %5.1f%% of  5%%\n" "Memory Problems" $vstr $errors

total=`echo "scale=2; $total + $ccode +$errors" | bc -l`
printf "\n%20s: %5.1f%%\n\n" "Total" $total 
