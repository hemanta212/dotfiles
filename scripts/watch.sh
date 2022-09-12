#!/bin/bash

### Set initial time of file
LTIME=`stat -c %Z temp.cpp`

while true    
do
   ATIME=`stat -c %Z temp.cpp`

   if [[ "$ATIME" != "$LTIME" ]]
   then    
       make run
       LTIME=$ATIME
   fi
   sleep 5
done
