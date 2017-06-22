#!/bin/bash

# Copyright: (C) 2016 iCub Facility - Istituto Italiano di Tecnologia
# Authors: Ugo Pattacini <ugo.pattacini@iit.it>
#          Daniele E. Domenichelli <daniele.domenichelli@iit.it>
# CopyPolicy: Released under the terms of the GNU GPL v2.0.

# Dependencies (through apt-get):
# - curl
# - jq

if [ $# -lt 2 ]
then
    echo "Usage: $0 <organization> <username> [token]"
    exit 1
fi

function queryx()
{
    local tokenstr=""
    if [ "$3" != "none" ]; then
        tokenstr="-H \"Authorization: token $3\""
    fi

    local ret=$(curl -s $tokenstr -G https://api.github.com/search/issues --data-urlencode "q=org:$1 $2" | jq -r .total_count)

    echo $ret
}


function query()
{
    q=$(queryx "$1" "$2" "$3")
    while [ "${q}" == "null" ]; do
        sleep 5
        q=$(queryx "$1" "$2" "$3")
    done

    echo -n $q
}


org=$1
name=$2
token="none"
rc=0


echo ""
if [ $# -ge 3 ]; then
    if [[ $3 =~ ^[0-9a-fA-F]+$ ]]; then
        token=$3
        echo "Computing robo-chlorians for \"$name\" on organization \"$org\" using token \"$token\"..."
    fi
fi

if [ "$token" == "none" ]; then
    echo "Computing robo-chlorians for \"$name\" on organization \"$org\"..."
fi
echo "GitHub might take a while to reply due to their rate limiter, thus just wait even if the process seems stuck."
echo ""





echo "Closed PRs:"

mult=16
printf "    author and merged (%02d robo-chlorians)                                " $mult
q=$(query "$org" "is:pr is:merged author:$name" $token)
let "k = $mult * $q"
printf "%5d => %5d\n" $q $k
let "rc = $rc + $k"

mult=4
printf "    author and not merged (rejected, withdrawn, etc) (%02d robo-chlorians) " $mult
# "-is:merged" does not work therefore we use closed - merged
qx=$q
q=$(query "$org" "is:pr is:closed author:$name" $token)
let "q = $q - $qx"
let "k = $mult * $q"
printf "%5d => %5d\n" $q $k
let "rc = $rc + $k"

mult=8
printf "    not author and assigned (%02d robo-chlorians)                          " $mult
q=$(query "$org" "is:pr is:closed -author:$name assignee:$name" $token)
let "k = $mult * $q"
printf "%5d => %5d\n" $q $k
let "rc = $rc + $k"

mult=4
printf "    involved (%02d robo-chlorians)                                         " $mult
q=$(query "$org" "is:pr is:closed -author:$name -assignee:$name involves:$name" $token)
let "k = $mult * $q"
printf "%5d => %5d\n" $q $k
let "rc = $rc + $k"




echo "Closed issues:"

mult=16
printf "    assigned (%02d robo-chlorians)                                         " $mult
q=$(query "$org" "is:issue is:closed assignee:$name" $token)
let "k = $mult * $q"
printf "%5d => %5d\n" $q $k
let "rc = $rc + $k"

mult=8
printf "    author and not assigned (%02d robo-chlorians)                          " $mult
q=$(query "$org" "is:issue is:closed -assignee:$name author:$name" $token)
let "k = $mult * $q"
printf "%5d => %5d\n" $q $k
let "rc = $rc + $k"

mult=4
printf "    involves and not author and not assigned (%02d robo-chlorians)         " $mult
q=$(query "$org" "is:issue is:closed -assignee:$name -author:$name involves:$name" $token)
let "k = $mult * $q"
printf "%5d => %5d\n" $q $k
let "rc = $rc + $k"



echo "Open PRs:"

mult=4
printf "    author (%02d robo-chlorians)                                           " $mult
q=$(query "$org" "is:pr is:open author:$name" $token)
let "k = $mult * $q"
printf "%5d => %5d\n" $q $k
let "rc = $rc + $k"


mult=2
printf "    not author and assigned (%02d robo-chlorians)                          " $mult
q=$(query "$org" "is:pr is:open -author:$name assignee:$name" $token)
let "k = $mult * $q"
printf "%5d => %5d\n" $q $k
let "rc = $rc + $k"


mult=1
printf "    involved (%02d robo-chlorians)                                         " $mult
q=$(query "$org" "is:pr is:open -author:$name -assignee:$name involves:$name" $token)
let "k = $mult * $q"
printf "%5d => %5d\n" $q $k
let "rc = $rc + $k"





echo "Open issues:"

mult=2
printf "    assigned (%02d robo-chlorians):                                        " $mult
q=$(query "$org" "is:issue is:open assignee:$name" $token)
let "k = $mult * $q"
printf "%5d => %5d\n" $q $k
let "rc = $rc + $k"


mult=1
printf "    author and not assigned (%02d robo-chlorians):                         " $mult
q=$(query "$org" "is:issue is:open -assignee:$name author:$name" $token)
let "k = $mult * $q"
printf "%5d => %5d\n" $q $k
let "rc = $rc + $k"


mult=1
printf "    involves and not author and not assigned (%02d robo-chlorians)         " $mult
q=$(query "$org" "is:issue is:open -assignee:$name -author:$name involves:$name" $token)
let "k = $mult * $q"
printf "%5d => %5d\n" $q $k
let "rc = $rc + $k"






echo   "--------------------------------------------------------------------------------------"
printf "Total robo-chlorians                                                             %5d\n" $rc
echo ""
