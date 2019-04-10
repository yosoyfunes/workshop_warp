#!/bin/bash

##
# Check if the .env file exist
#
# Globals:
#   PROJECTPATH
# Arguments:
#   None
# Returns:
#   0 if exists
#   1 if not exists
##
warp_check_env_file()
{
    if [ -f $ENVIRONMENTVARIABLESFILE ]; then
        return 0 #TRUE
    else
        return 1 #FALSE
    fi;
}


##
# Check if the docker-compose.yml file exist
#
# Globals:
#   PROJECTPATH
# Arguments:
#   None
# Returns:
#   0 if exists
#   1 if not exists
##
warp_check_yaml_file()
{
    if [ -f $DOCKERCOMPOSEFILE ]; then
        return 0 #TRUE
    else
        return 1 #FALSE
    fi;
}

##
# Check if files exist
#
# * docker-compose-warp.yml
# * docker-sync.yml
# * .env
#
# Globals:
#   PROJECTPATH
# Arguments:
#   None
##
function warp_check_files()
{
    INFRA_FILES_ERROR="FALSE"
    INFRA_FILES_ERROR_MAC="FALSE"

    if [ ! -f $DOCKERCOMPOSEFILE ]; then
        INFRA_FILES_ERROR="TRUE"
        echo "* Checking file $(basename $DOCKERCOMPOSEFILE) $(warp_message_error [error])"
    fi; 
    
    if [ ! -f $ENVIRONMENTVARIABLESFILE ]; then
        INFRA_FILES_ERROR="TRUE"
        echo "* Checking file $(basename $ENVIRONMENTVARIABLESFILE) $(warp_message_error [error])"
    fi;

    case "$(uname -s)" in
        Darwin)
        if [ ! -f $DOCKERSYNCMAC ]; then
            INFRA_FILES_ERROR_MAC="TRUE"
            echo "* Checking file $(basename $DOCKERSYNCMAC) $(warp_message_error [error])"
        fi;
        ;;
    esac    

    if [ $INFRA_FILES_ERROR = "TRUE" ]; then
        warp_message ""
        warp_message_warn "-- These files: ($(basename $DOCKERCOMPOSEFILE) and $(basename $ENVIRONMENTVARIABLESFILE)) are necessary to initialize the containers.. $(warp_message_error [error])"
        [ $INFRA_FILES_ERROR_MAC = "TRUE" ] && warp_message_warn "-- This files: $(basename $DOCKERSYNCMAC) is necessary in macOS.. $(warp_message_error [error])"
        warp_message_warn "-- To initialize the project please Run: $(warp_message_bold './warp init')"
        exit
    fi
}

# WARNING MESSAGE IF TO USE MAC 
# MacOS not soport multi-projects
warp_check_os_mac() {
    case "$(uname -s)" in
        Darwin)
        # autodetect docker in Mac
            warp_message_warn "Warning! Docker for Mac does not support more than one project in parallel"
            warp_message_info "starting simple project.."
            warp_message ""
        ;;
    esac    
}

#######################################
# Check if the docker-components are running
# Globals:
#   DOCKERCOMPOSEFILE
# Arguments:
#   None
# Returns:
#   true|false
#######################################
warp_check_is_running() {
    if [ -f $DOCKERCOMPOSEFILE ]
    then
        #dockerStatusOutput=$(docker-compose -f $DOCKERCOMPOSEFILE ps -q | xargs docker inspect --format='{{ .State.Status }}' | sed 's:^/::g' | grep -i running)
        dockerStatusOutput=$(docker-compose -f $DOCKERCOMPOSEFILE ps --filter status=running --services)
        outputSize=${#dockerStatusOutput}
        if [ "$outputSize" -gt 0 ]; then
            echo true
        else
            echo false
        fi
    else
        echo false
    fi
}

warp_check_php_is_running() {
    if [ -f $DOCKERCOMPOSEFILE ]
    then
        COUNT=0
        while : ; do
            #dockerStatusOutput=$(docker-compose -f $DOCKERCOMPOSEFILE ps -q php | xargs docker inspect --format='{{ .State.Status }}' | sed 's:^/::g' | grep -i running)
            dockerStatusOutput=$(docker-compose -f $DOCKERCOMPOSEFILE ps -q php)
            outputSize=${#dockerStatusOutput}
            if [ "$outputSize" -gt 0 ]; then
                echo true
                break
            else
                sleep 1
                let COUNT=$COUNT+1
                [ $COUNT = 5 ] && echo false && break
            fi
        done        
    else
        echo false
    fi
}
