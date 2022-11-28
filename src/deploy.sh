#!/bin/bash

# need to add some command line handling here
# also error handling


source ./colors

keyfolder=keys
mkdir $keyfolder
export ANSIBLE_HOST_KEY_CHECKING=False

invFile="hosts.yml"
playBook="deploy.yml"
IPs=$(grep ansible_host ${invFile} | awk '{print $2}' | sort -u)
PORTs=$(grep ansible_port ${invFile} | awk '{print $2}' | sort -u)
USER_LIST="A B C D E F" #user list, replace with real users. 


usage() { 
    printf "Usage: "
}

if [[ ! $(which sshpass) ]]; then
    echo -e " ${ltYellow}sshpass:\t ${ltRed}NO${end}${DIM} ( required )${end}\n"
    exit 1
else
    echo -e " ${ltYellow}sshpass:\t ${end}${green}$(which sshpass)${end}\n"
fi

echo " Scrubbing inventory from known_hosts..."
for ip in ${IPs}; do
    echo -en " ${ip}..."
    r=$(ssh-keygen -R ${ip} 2>&1 > /dev/null)
    if [[ $r = *"not found"* ]]; then echo -e "${ltYellow}NULL${end}"; else echo -e "${ltRed}DELETED${end}"; fi
    for port in ${PORTs}; do
        echo -en " ${ip}:${port}..."
        r=$(ssh-keygen -R ${ip}:${port} 2>&1 > /dev/null)
        if [[ $r = *"not found"* ]]; then echo -e "${ltYellow}NULL${end}"; else echo -e "${ltRed}DELETED${end}"; fi
    done
done
echo 


for keyname in $USER_LIST
do
    if [ ! -e $keyfolder/${keyname}_id ]
    then
        ssh-keygen -t rsa -b 4096 -q -N "" -f "${keyfolder}/${keyname}_id"
        echo -e "${keyname}_id is ${yellow}added${end}"
    else
        echo -e "${keyname}_id ${green}exists${end}"
    fi
done

# run the pre SSH change commands

ansible-playbook -i ${invFile} -b ${playBook} -k $@
