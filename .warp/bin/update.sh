#!/bin/bash

    # IMPORT HELP

    . "$PROJECTPATH/.warp/bin/update_help.sh"

function update_command() {

  if [ "$1" = "-h" ] || [ "$1" = "--help" ] ; then
        
      update_help_usage
      exit 1;
  else

      warp_setup update
  fi;
}

function update_main()
{
    case "$1" in
        update)
          shift 1
          update_command $*
        ;;

        *)
          update_help_usage
        ;;
    esac
}
