#!/bin/bash

#Check meetings prams
APICallName="getMeetings"
X=$( bbb-conf --secret | fgrep URL: )
APIEndPoint=${X##* }
Y=$( bbb-conf --secret | fgrep Secret: )
Secret=${Y##* }
S=$APICallName$APIQueryString$Secret
Checksum=$( echo -n $S | sha1sum | cut -f 1 -d ' ' )

while [ True ]
do
    #check number of meetings
    URL="${APIEndPoint}api/$APICallName?checksum=$Checksum"
    meetings=$(wget -q -O - "$URL" | grep -o '<meetingID>' | wc -w)
    echo | awk -v m="${meetings}" '{print "Meetings running: " m}'
    #check cpu for recordings process
    cores=$(nproc)
    load=$(awk '{print $2}'< /proc/loadavg)
    echo | awk -v c="${cores}" -v l="${load}" '{print "Relative load: " l*100/c "%"}'
    usage=$(echo | awk -v c="${cores}" -v l="${load}" '{print l*100/c}' | awk -F. '{print $1}')

    if [[ ${usage} -lt 5 ]] && [[ ${meetings} -eq "0" ]] ; then
        echo "Transferring Recordings"
        sudo /bin/bash /usr/local/bigbluebutton/core/scripts/scalelite_batch_import.sh
        echo "Server will shutdown"
        sudo bbb-conf --stop
        sleep 60
        sudo shutdown now
    else
        echo "Server is still working"
    fi
    sleep 60
done