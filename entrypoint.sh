#!/usr/bin/env bash

TRUE=$(which true)

if [[ -z ${NAMESPACE+x} ]]; then
  NAMESPACE="default"
fi

echo "Namespace set to ${NAMESPACE}"

if [[ -z ${DATABASE_HOSTNAME+x} ]]; then
  echo "Missing DATABASE_HOSTNAME"
  exit 1
fi

if [[ -z ${DATABASE_PORT+x} ]]; then
	echo "Setting default value for DATABASE_PORT=3306"
	DATABASE_PORT=3306
fi

if [[ -z ${DATABASE_MASTER_USERNAME+x} ]]; then
  echo "Missing DATABASE_MASTER_USERNAME"
  exit 1
fi

if [[ -z ${DATABASE_MASTER_PASSWORD+x} ]]; then
  echo "Missing DATABASE_MASTER_PASSWORD"
  exit 1
fi

function check_database() {
	database=$1
	username=$2
	password=$3

	if [[ $database == "" || $username == "" || $password == "" ]]; then
		echo "check_database: Missing database, username or password"
		return 1
	fi

  sql="SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = '"${database}"'"
	result=$(echo $sql | mysql -h ${DATABASE_HOSTNAME} -u ${DATABASE_MASTER_USERNAME} -p${DATABASE_MASTER_PASSWORD})
	if [[ ${result} != "" ]]; then
    echo "check_database: database $database already exists"
		return 1
	fi

  echo "check_database: database $database does not exist"
	return 0
}

function create_database() {
	database=$1
	username=$2
	password=$3

	if [[ $database == "" || $username == "" || $password == "" ]]; then
		echo "create_database: Missing database, username or password"
		return 1
	fi

  echo "create_database: Will create database $database"
	echo 'CREATE DATABASE IF NOT EXISTS `'${database}'`' | mysql --wait -h ${DATABASE_HOSTNAME} -u ${DATABASE_MASTER_USERNAME} -P ${DATABASE_PORT} -p${DATABASE_MASTER_PASSWORD}
	echo "CREATE USER IF NOT EXISTS '${username}'@'%' IDENTIFIED BY '${password}'" | mysql --wait -h ${DATABASE_HOSTNAME} -u ${DATABASE_MASTER_USERNAME} -P ${DATABASE_PORT} -p${DATABASE_MASTER_PASSWORD}
	echo "GRANT ALL PRIVILEGES ON \`${database}\`.* TO '${username}'@'%'" | mysql --wait -h ${DATABASE_HOSTNAME} -u ${DATABASE_MASTER_USERNAME} -P ${DATABASE_PORT} -p${DATABASE_MASTER_PASSWORD}
	echo 'FLUSH PRIVILEGES' | mysql --wait -h ${DATABASE_HOSTNAME} -u ${DATABASE_MASTER_USERNAME} -P ${DATABASE_PORT} -p${DATABASE_MASTER_PASSWORD}

	return 0
}

set -u

while ${TRUE}; do
	date
	for secret in $(kubectl -n ${NAMESPACE} get secret -l docker-rds=true --no-headers -o name); do
		echo "Found secret $secret"
		database=$(kubectl -n ${NAMESPACE} get ${secret} -o jsonpath="{.data.database}" | base64 --decode)
		username=$(kubectl -n ${NAMESPACE} get ${secret} -o jsonpath="{.data.username}" | base64 --decode)
		password=$(kubectl -n ${NAMESPACE} get ${secret} -o jsonpath="{.data.password}" | base64 --decode)
		if [[ $database != "" && $username != "" && $password != "" ]]; then
			check_database $database $username $password
			if [[ $? == 0 ]]; then
				create_database $database $username $password
			fi
		else
			echo "Missing database, username or password in secret $secret"
		fi
	done

	sleep 60
done
