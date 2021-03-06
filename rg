#!/bin/bash

help-text() {
cat << END
  _ __ __ _   
 | '__/ _\` |  
 | | | (_| |_ 
 |_|  \\__, (_)
      |___/   
A command line tool for managing default Azure resource groups
Author: Lee Cattarin - github.com/lee0c
v0.1.2

    rg              : Lists all resource groups in the current Azure subscription. The 
                        default resource group, if set, will be highlighted. Any
                        managed cluster (such as those used for AKS) or cluster tagged
                        with "rgcli_deprioritize" will be de-prioritized.
    rg <NAME>       : Sets the given resource group as default for Azure CLI commands. 
    rg -u, --unset  : Removes any configured default resource group.
    rg -h, --help   : Displays this text.
END
}

error-text() {
cat << END
USAGE: rg [OPTION|NAME]
See rg --help for more information.
END
}

# If no arguments, list resource groups
if [[ $# = 0 ]]
then
    current=$(az configure --list-defaults --query "[?name=='group'].value" -o tsv)
    managed=$(az group list --query "[?managedBy!=null].name" -o tsv)
    deprioritized=""
    # List resource groups with current one highlighted
    for group in $(az group list --query "[?managedBy==null].name" -o tsv)
    do
        if [[ "$group" = "$current" ]]
        then
            echo -e "\e[1;92m$group\e[0;39m"
        else
            [[ -z $(az group show -g $group --query "tags.rgcli_deprioritize") ]] && echo -e $group || deprioritized="$deprioritized $group"
        fi
    done

    echo "---"
    
    for group in $deprioritized
    do
        echo -e "\e[2;39m$group\e[0;39m"
    done

    for group in $managed
    do
        echo -e "\e[2;39m$group\e[0;39m"
    done
fi

# Handle all other arguments
while [[ $# > 0 ]]
do
    case $1 in
    -h|--help)
        help-text
        exit 0
        ;;
    -u|--unset)
        az configure --defaults group=''
        echo "Default resource group unset"
        exit 0
        ;;
    -*)
        error-text
        exit 0
        ;;
    *)
        echo $1
        if [[ $(az group exists --name $1 -o tsv) = true ]]
        then

            # Set group as current context
            az configure --defaults group=$1
            echo "Default resource group set to $1"
        else
            echo "Specified resource group doesn't exist in the current subscription"
        fi
        exit 0
        ;;
    esac
done