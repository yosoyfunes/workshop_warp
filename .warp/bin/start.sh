#!/bin/bash

    # IMPORT HELP

    . "$PROJECTPATH/.warp/bin/start_help.sh"

#######################################
# Start the server and all of its
# components
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
#######################################
function start() {

  if [ $(warp_check_is_running) = true ]; then
    warp_message_warn "the containers is running";
    warp_message_warn "for stop, please run: warp stop";
    exit 1;
  fi

  if [ "$1" = "-h" ] || [ "$1" = "--help" ] ; then
        
      start_help_usage
      exit 1;
  else

    # Check 
    warp_check_files

    case "$(uname -s)" in
      Darwin)
        # start data sync
        docker-sync start
        # start docker containers in macOS
        docker-compose -f $DOCKERCOMPOSEFILE -f $DOCKERCOMPOSEFILEMAC up -d
      ;;
      Linux)
        # start docker containers in linux
        docker-compose -f $DOCKERCOMPOSEFILE up -d
      ;;
    esac

    if [ $(warp_check_php_is_running) = true ]
    then
      # COPY ID_RSA ./ssh
      copy_ssh_id
      # Initialize Cron Job
      crontab_run

      # Starting Supervisor service
      docker-compose -f $DOCKERCOMPOSEFILE exec -d --user=root php bash -c "service supervisor start 2> /dev/null"

    else
      warp_message_warn "Please Run ./warp composer --credential to copy the credentials"
    fi
  fi;
}

function start_main()
{
    case "$1" in
        start)
          shift 1
          start $*
        ;;

        *)
          start_help_usage
        ;;
    esac
}
