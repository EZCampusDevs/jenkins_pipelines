#!/bin/bash

USE_LOG_FILE_ARGUMENT="USE_LOG_FILE"

if [ $# != 0 ]; then

   echo "Processing start arguments"

   for arg in "$@"; do

      if [ "$arg" = "$USE_LOG_FILE_ARGUMENT" ]; then

         echo "Writing all stdout and stderr to file"

         log_dir="$HOME/log/jenkins-ssh"
         mkdir -p $log_dir

         log_file="$log_dir/mysql-jenkins-setup-log.out"
         touch log_file

         exec 3>&1 4>&2
         trap 'exec 2>&4 1>&3' 0 1 2 3
         exec 1>$log_file 2>&1

      fi

   done

fi

if [ -e "env.sh" ] && [ -x "env.sh" ]; then 

    source "env.sh"

fi

DB_NAME="ezcampus_db"

CONTAINER_NAME="mysql-instance"


if docker ps -a --format '{{.Names}}' | grep -Eq "^${CONTAINER_NAME}$"; then

    echo "Docker container with name $CONTAINER_NAME already exists, it must be removed first"

    exit 1

fi


if [[ ! -z "${ROOT_PASSWORD}" ]]; then

    echo "Docker run creating container with name: $CONTAINER_NAME"

    docker run --name $CONTAINER_NAME -p 127.0.0.1:3306:3306 -e MYSQL_ROOT_PASSWORD=$ROOT_PASSWORD -d --network=EZnet mysql

else

    echo "ROOT_PASSWORD env var is not set, this is required!"

    exit 1

fi
