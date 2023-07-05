#!/bin/sh

USE_LOG_FILE_ARGUMENT="USE_LOG_FILE"

if [ $# != 0 ]; then

   echo "Processing start arguments"

   for arg in "$@"; do

      if [ "$arg" = "$USE_LOG_FILE_ARGUMENT" ]; then

         echo "Writing all stdout and stderr to file"

         log_dir="$HOME/log/jenkins-ssh"
         mkdir -p $log_dir

         log_file="$log_dir/mysql-jenkins-setup-log.out"
         touch $log_file

         exec 3>&1 4>&2
         trap 'exec 2>&4 1>&3' 0 1 2 3
         exec 1>$log_file 2>&1

      fi

   done

fi

if [ -e "env.sh" ] && [ -x "env.sh" ]; then 

    . ./env.sh

fi

DB_NAME="ezcampus_db"

CONTAINER_NAME="mysql-instance"


if docker ps -a --format '{{.Names}}' | grep -Eq "^${CONTAINER_NAME}$"; then

    echo "Docker container with name $CONTAINER_NAME already exists, it must be removed first"

    exit 1

fi


if [ -n "${ROOT_PASSWORD}" ]; then

    echo "Docker run creating container with name: $CONTAINER_NAME"

    docker run --name $CONTAINER_NAME -p 127.0.0.1:3306:3306 -e MYSQL_DATABASE="$DB_NAME" -e MYSQL_ROOT_PASSWORD="$ROOT_PASSWORD" -d --network=EZnet mysql

else

    echo "ROOT_PASSWORD env var is not set, this is required!"

    exit 1

fi

while true; do

    echo "Waiting for MySQL to respond..."

    docker exec $CONTAINER_NAME mysqladmin ping -uroot -p"${ROOT_PASSWORD}" &>/dev/null && break

    sleep 1
done

echo "MySQL server is ready, creating users..."

# Checking if MySQL is Ready
echo "Checking MySQL status..."
while :
do
    docker exec $CONTAINER_NAME mysql -uroot -p$ROOT_PASSWORD -e "status" > /dev/null 2>&1
    result=$?
    if [ $result -eq 0 ]; then
        echo "MySQL is ready."
        break
    else
        echo "MySQL is not ready yet, waiting..."
        sleep 1
    fi
done

# Creating a database
echo "Creating a database..."
docker exec $CONTAINER_NAME mysql -uroot -p$ROOT_PASSWORD -e "CREATE DATABASE $DB_NAME;"

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


echo "Setup is completed successfully!"