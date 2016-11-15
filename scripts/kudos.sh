#!/bin/bash

# Copyright: (C) 2016 iCub Facility - Istituto Italiano di Tecnologia
# Authors: Ugo Pattacini <ugo.pattacini@iit.it>
# CopyPolicy: Released under the terms of the GNU GPL v2.0.

# Dependencies (through apt-get):
# - curl
# - jq

if [ $# -eq 0 ]
then
    echo "Usage: kudos user-name"
    exit
fi

function query()
{
    local res="$(curl -s https://api.github.com/search/issues?q=org%3Arobotology+$1 | jq -r .total_count)"
    echo "$res"
}

name=$1
echo "Computing kudos for $name..."

q_0=$(query "is%3Aclosed+assignee%3A$name")
q_1=$(query "is%3Aclosed+-assignee%3A$name+author%3A$name")
q_2=$(query "is%3Aclosed+-assignee%3A$name+-author%3A$name+involves%3A$name")
q_3=$(query "is%3Aopen+assignee%3A$name")
q_4=$(query "is%3Aopen+-assignee%3A$name+author%3A$name")
q_5=$(query "is%3Aopen+-assignee%3A$name+-author%3A$name+involves%3A$name")

op="kudos = 16 * $q_0 + 8 * $q_1 + 4 * $q_2 + 4 * $q_3 + 2 * $q_4 + $q_5"
let "$op"
echo "$op = $kudos"
