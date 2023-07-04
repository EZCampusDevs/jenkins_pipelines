#!/bin/sh

USE_LOG_FILE_ARGUMENT="USE_LOG_FILE"

if [ $# != 0 ]; then

   echo "Processing start arguments"

   for arg in "$@"; do

      if [ "$arg" = "$USE_LOG_FILE_ARGUMENT" ]; then

         echo "Writing all stdout and stderr to file"

         log_dir="$HOME/log/jenkins-ssh"
         mkdir -p $log_dir

         log_file="$log_dir/mysql-users-create-log.out"
         touch $log_file

         exec 3>&1 4>&2
         trap 'exec 2>&4 1>&3' 0 1 2 3
         exec 1>$log_file 2>&1

      fi

   done

fi

# Create a list of usernames and passwords
usernames=("$MYSQL_USERNAME_1" "$MYSQL_USERNAME_2" "$MYSQL_USERNAME_3")
passwords=("$MYSQL_USER_PASS_1" "$MYSQL_USER_PASS_2" "$MYSQL_USER_PASS_3")

# Loop over each username/password and create the corresponding MySQL user with permissions
for i in "${!usernames[@]}"; do
    username=${usernames[i]}
    password=${passwords[i]}

    if [[ ! -z "${username}" ]] && [[ ! -z "${password}" ]]; then
        echo "Creating MySQL user with name $username"

        # You may need to adjust the command below depending on how you're interfacing with MySQL
        # The example below assumes you're using docker exec to run the MySQL commands
        docker exec $CONTAINER_NAME mysql -uroot -p"${ROOT_PASSWORD}" -e "CREATE USER '${username}'@'%' IDENTIFIED BY '${password}';"
        docker exec $CONTAINER_NAME mysql -uroot -p"${ROOT_PASSWORD}" -e "GRANT ALL PRIVILEGES ON *.* TO '${username}'@'%' WITH GRANT OPTION;"
    else
        echo "No environment variable set for username/password at index $i"
        exit 1
    fi
done
