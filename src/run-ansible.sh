#!/bin/bash

# Quick n Dirty script to help others run ansible deployments on the fly. 
# TODO: needs more documentation. 
# Samuel E. Bray
source ./colors

VIEW=0
INVENTORY=""
INV_IP=""
INV_FILE=""
PLAYBOOK=""
ANSIBLE_PLAYBOOK_COMMAND="ansible-playbook"
OTHER_COMMANDS=""
CHECK=""
LINODE="echo 'no linode-cli'" # WTF
LINODE_NODES=""

# Turn off host key checking in ansible, also should be turned off in inventory.
export ANSIBLE_HOST_KEY_CHECKING=False


print_help() {
    printf "${DIM}${magenta}Usage: ${end} "
    printf "$(basename $0) ${DIM}${ltBlue}[options]\n"
    printf "Options:${end}\n"
    printf "\t-a, --ansible\t ${DIM}${yellow} /path/to/ansible-playbook ${end}\n"
    printf "\t-c, --check\t ${DIM}${yellow} Run ansible in CHECK mode (-C)${end}\n"
    printf "\t-f, --inventory\t ${DIM}${yellow} /path/to/inventory/file${end}\n"
    printf "\t-i, --ip\t ${DIM}${yellow} Use IP address for ansible host${end}\n"
    printf "\t-l, --list\t ${DIM}${yellow} Use IP address list for ansible hosts ${red}(TODO)${end}\n" #TODO:
    printf "\t-p, --playbook\t ${DIM}${yellow} /path/to/playbook/file${end}\n"
    printf "\t-o, --other\t ${DIM}${yellow} \"Quoted list of ansible-playbook options\"${end}\n"
    printf "\t-u, --users\t ${DIM}${yellow} \"Quoted space separated list of users to add\" ${red}(TODO)${end}\n" #TODO:
    printf "\t-w, --view\t ${DIM}${yellow} View the ansible-playbook command rather than executing it${end}\n"
    printf "\t-v, --verbose\t ${DIM}${yellow} Run ansible-playbook verbose${end}\n"
    printf "\t-h, --help\t ${DIM}${yellow} This help${end}\n\n"

    printf "\tThings you'll need:\n"
    printf "\t - ansible\n"
    printf "\t - sshpass\n"
    printf "\t - linode-cli\n"
    printf "\t - python\n"
}

### Handle command line input
if [[ -z $1 ]]; then
    print_help
    exit 0
fi

TEMP=$(getopt -o 'a:cChi:o:p:u:vw' --long 'ansible:,check,help,ip:,inventory:,other:,playbook:,users:,view,verbose' -n "$(basename $0)" -- "$@")
if [[ $? -ne 0 ]]; then
    echo -e "${DIM}${RED}Terminating...${end}\n" >&2
    print_help
    exit 1
fi
eval set -- "$TEMP"
unset TEMP

while true; do
    case "$1" in
        '-a'|'--ansible')
            ANSIBLE_PLAYBOOK_COMMAND=$2
            shift 2
            continue
            ;;

        '-c'|'-C'|'--check')
            CHECK="-C"
            shift
            continue
            ;;
        
        '-h'|'--help')
            print_help
            exit 0
            ;;

        '-f'|'--inventory')
            INV_FILE=$2
            shift 2
            continue
            ;;

        '-i'|'--ip')
            INV_IP=$2
            shift 2
            continue
            ;;

        '-p'|'--playbook')
            PLAYBOOK=$2
            shift 2
            continue
            ;;

        '-o'|'--other')
            OTHER_COMMANDS="${OTHER_COMMANDS} $2"
            shift 2
            continue
            ;;

        '-u'|'--users')
            USERS=$2
            shift 2
            continue
            ;;
        
        '-w'|'--view')
            VIEW=1
            shift 1
            continue
            ;;

        '-v'|'--verbose')
            OTHER_COMMANDS="${OTHER_COMMANDS} -vvv"
            shift 1
            continue
            ;;
        
        '--')
            shift
            break
            ;;

        *)
            echo 'Internal error!' >&2
            exit 1
            ;;
    esac
done

#Start house keeping 
printf "\n"
printf "Setting up...\n"

# Handle Inventory

#
#IP List 
# if [[ ${INVENTORY:(-1)} = "," ]]; then 

#     IPs=${INVENTORY%,}

#     printf "IP: ${IPs}\n"
# fi

#IP
if [[ -n "${INV_IP}" ]]; then
    # We've been passed an IP
    printf "${INV_IP} \t"
    IPs=${INV_IP}
    INVENTORY="${INV_IP},"
    PORTs=""
else
#Inventory File
    printf "${INV_FILE} \t"
     if [[ ! -s ${INV_FILE} ]]; then 
        printf "${red}NOT FOUND\n"
        exit 1
    else 
        printf "${green}OK"; 
    fi
     IPs=$(grep ansible_host ${INV_FILE} | awk '{print $2}' | sort -u)
     PORTs=$(grep ansible_port ${INV_FILE} | awk '{print $2}' | sort -u) 
     INVENTORY="${INV_FILE}"
fi

#Handle Playbook
printf "${end}\n ${PLAYBOOK}: \t"
if [[ ! -s ${PLAYBOOK} ]]; then 
    printf "${red}NOT FOUND\n" 
    exit 1
else 
    printf "${green}OK"; 
fi
printf "${end}\n"

# TODO: check this stuff first
# TODO: add as a separate command option 
# TODO: move to top
# TODO: make this a function. 

# Check for apps
# Required: ansible, sshpass
# Optional: linode-cli and jq (for now)
printf " ${ANSIBLE_PLAYBOOK_COMMAND}:\t"
if [[ ! $(which "${ANSIBLE_PLAYBOOK_COMMAND}") ]]; then
    printf "${ltRed}NOT FOUND${end}${DIM} ( required )${end}\n"
    exit 1
else
    printf "${green}$(which ${ANSIBLE_PLAYBOOK_COMMAND})${end}\n"
fi
printf " sshpass:\t\t" 
if [[ ! $(which sshpass) ]]; then
    printf "${ltRed}NOT FOUND${end}${DIM} ( required )${end}\n"
    exit 1
else
    printf "${green}$(which sshpass)${end}\n"
fi

# FIXME: Fix this
# check for linode-cli
# TODO: something useful
printf " linode-cli:\t\t"
if [[ ! $(which linode-cli) ]]; then 
    printf "${yellow}Gonna need this maybe${end}\n"
else
    printf "${green}$(which linode-cli)${end}\n"
    linodeProfile=$(linode-cli --no-headers --text profile view 2>/dev/null)
    linodeUser=$(echo ${linodeProfile} | awk '{print $1}')
    printf " Linode user:\t\t"
    if [[ -n ${linodeUser} ]]; then
        printf "${DIM}${magenta}${linodeUser}${end}\n"
    else
        printf "${red}NONE${end} "
        printf "${DIM}( Maybe run: ${magenta}linode-cli configure${end}${DIM} )${end}\n"
    fi
fi
printf " jq:\t\t\t"
if [[ ! $(which jq) ]]; then
    printf "${ltYellow}Gonna need this to use linode-cli${end}\n"
else
    printf "${green}$(which jq)${end}\n"
fi

# Clean IPs & Ports from .ssh/kown_hosts just to 
# make sure we don't try to use old host w/ new ssh_key
printf "\nScrubbing hosts (safely) found in '${DIM}${yellow}${INVENTORY}${end}' from '${DIM}${yellow}${HOME}/.ssh/known_hosts${end}'...\n"
for ip in ${IPs}; do
    printf " ${ip}..."
    r=$(ssh-keygen -R ${ip} 2>&1 > /dev/null)
    if [[ $r = *"not found"* ]]; then 
        printf "${green}OK${end}\n" 
    else 
        printf "${DIM}${ltRed}DELETED${end}\n"
    fi
    for port in ${PORTs}; do
        printf " ${ip}:${port}..."
        r=$(ssh-keygen -R ${ip}:${port} 2>&1 > /dev/null)
        if [[ $r = *"not found"* ]]; then 
            printf "${green}OK${end}\n"
        else 
            printf "${DIM}${ltRed}DELETED${end}\n"
        fi
    done
done

printf "\n"
#end house keeping

#Run ansible
# TODO:  I need a function!

RUN_ME="${ANSIBLE_PLAYBOOK_COMMAND} -k -i ${INVENTORY} ${PLAYBOOK} ${OTHER_COMMANDS} ${CHECK}"

#FAKE NEWS!!!!
if [[ $VIEW -ne 0 ]]; then
    printf "${DIM}${ltBlue}Command:\t ${end}${RUN_ME}\n\n"
else

#RUN FOR REAL
    printf "${ltRed}Running:\t ${end}${RUN_ME}\n\n"
    ${RUN_ME}
    ansibleRet=$?
    printf "\n${end}Ansible returned:  "
    if [[ $ansibleRet -ne 0 ]]; then
        printf "${red}FAIL ${ansibleRet}${end}\n"
    else
        printf "${green}SUCESS ${ansibleRet}${end}\n"
    fi
fi

