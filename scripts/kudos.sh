#!/bin/bash

# Copyright: (C) 2016 iCub Facility - Istituto Italiano di Tecnologia
# Authors: Ugo Pattacini <ugo.pattacini@iit.it>
#          Daniele E. Domenichelli <daniele.domenichelli@iit.it>
# CopyPolicy: Released under the terms of the GNU GPL v2.0.

# Dependencies (through apt-get):
# - curl
# - jq

if [ $# -eq 0 ]
then
    echo "Usage: kudos username [token]"
    exit 1
fi

function query()
{
    local tokenstr=""
    if [ "$2" != "none" ]; then
        tokenstr="-H \"Authorization: token $2\""
    fi
    local res="$(curl -s $tokenstr https://api.github.com/search/issues?q=org%3Arobotology+$1 | jq -r .total_count)"
    echo "$res"
}

name=$1
token="none"

if [ $# -ge 2 ]; then
    if [[ $2 =~ ^[0-9a-fA-F]+$ ]]; then
        token=$2
        echo "Computing kudos for \"$name\" using token \"$token\"..."
    fi
fi

if [ "$token" == "none" ]; then
    echo "Computing kudos for \"$name\"..."
fi


q_0=$(query "is%3Aclosed+assignee%3A$name" $token)
sleep 0.5
q_1=$(query "is%3Aclosed+-assignee%3A$name+author%3A$name" $token)
sleep 0.5
q_2=$(query "is%3Aclosed+-assignee%3A$name+-author%3A$name+involves%3A$name" $token)
sleep 0.5
q_3=$(query "is%3Aopen+assignee%3A$name" $token)
sleep 0.5
q_4=$(query "is%3Aopen+-assignee%3A$name+author%3A$name" $token)
sleep 0.5
q_5=$(query "is%3Aopen+-assignee%3A$name+-author%3A$name+involves%3A$name" $token)
sleep 0.5

for q_i in q_0 q_1 q_2 q_3 q_4 q_5; do
    if [ "${!q_i}" == "null" ]; then
        echo "Wrong username/token or API rate limit exceeded (see https://developer.github.com/v3/#rate-limiting)"
        exit 2
    fi
done

op="kudos = 16 * $q_0 + 8 * $q_1 + 4 * $q_2 + 4 * $q_3 + 2 * $q_4 + $q_5"
let "$op"
echo "$op = $kudos"
