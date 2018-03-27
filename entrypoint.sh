#!/usr/bin/env bash

if [[ -z ${DATABASE_USERNAME+x} ]]; then
  echo "Missing DATABASE_USERNAME"
  exit 1
fi

if [[ -z ${DATABASE_PASSWORD+x} ]]; then
  echo "Missing DATABASE_PASSWORD"
  exit 1
fi

if [[ -z ${DATABASE_URL+x} ]]; then
  echo "Missing DATABASE_URL"
  exit 1
else
  if ! [[ ${DATABASE_URL} =~ ^jdbc:mysql:// ]]; then
    echo "DATABASE_URL=${DATABASE_URL} is not correctly formatted JDBC + MySQL."
    exit 1
  fi

  DATABASE_HOSTNAME=$(echo $DATABASE_URL | sed 's|^jdbc:mysql://||' | cut -d ':' -f 1)
  DATABASE_PORT=$(echo $DATABASE_URL | sed 's|^jdbc:mysql://||' | cut -d ':' -f 2 | cut -d '/' -f 1)
  DATABASE_NAME=$(echo $DATABASE_URL | sed 's|^jdbc:mysql://||' | cut -d '/' -f 2 | cut -d '?' -f 1)
fi

# -- Parse AWS SSM parameters

set -e

if [[ -z ${DATABASE_MASTER_USERNAME+x} ]]; then
  echo "Missing DATABASE_MASTER_USERNAME"
  exit 1
else
  if [[ ${DATABASE_MASTER_USERNAME} =~ ^ssm: ]]; then
    DATABASE_MASTER_USERNAME=$(aws ssm get-parameter --name $(echo ${DATABASE_MASTER_USERNAME} | cut -d ':' -f 2) --with-decryption --query Parameter.Value --output text);
  fi
fi

if [[ -z ${DATABASE_MASTER_PASSWORD+x} ]]; then
  echo "Missing DATABASE_MASTER_PASSWORD"
  exit 1
else
  if [[ ${DATABASE_MASTER_PASSWORD} =~ ^ssm: ]]; then
    DATABASE_MASTER_PASSWORD=$(aws ssm get-parameter --name $(echo ${DATABASE_MASTER_PASSWORD} | cut -d ':' -f 2) --with-decryption --query Parameter.Value --output text);
  fi
fi

set -u
set +e

if [[ -v DEBUG && ${DEBUG} == "true" ]]; then
  echo "DATABASE_HOSTNAME: $DATABASE_HOSTNAME"
  echo "DATABASE_PORT: $DATABASE_PORT"
  echo "DATABASE_NAME: $DATABASE_NAME"
  echo "DATABASE_USERNAME: $DATABASE_USERNAME"
  echo "DATABASE_PASSWORD: $DATABASE_PASSWORD"
  echo "DATABASE_MASTER_USERNAME: $DATABASE_MASTER_USERNAME"
  echo "DATABASE_MASTER_PASSWORD: $DATABASE_MASTER_PASSWORD"
  set -x
fi

echo 'CREATE DATABASE IF NOT EXISTS `'${DATABASE_NAME}'`' | mysql --wait -h ${DATABASE_HOSTNAME} -u ${DATABASE_MASTER_USERNAME} -P ${DATABASE_PORT} -p${DATABASE_MASTER_PASSWORD}
echo "CREATE USER IF NOT EXISTS '${DATABASE_USERNAME}'@'%' IDENTIFIED BY '${DATABASE_PASSWORD}'" | mysql --wait -h ${DATABASE_HOSTNAME} -u ${DATABASE_MASTER_USERNAME} -P ${DATABASE_PORT} -p${DATABASE_MASTER_PASSWORD}
echo "GRANT ALL PRIVILEGES ON \`${DATABASE_NAME}\`.* TO '${DATABASE_USERNAME}'@'%'" | mysql --wait -h ${DATABASE_HOSTNAME} -u ${DATABASE_MASTER_USERNAME} -P ${DATABASE_PORT} -p${DATABASE_MASTER_PASSWORD}
echo 'FLUSH PRIVILEGES' | mysql --wait -h ${DATABASE_HOSTNAME} -u ${DATABASE_MASTER_USERNAME} -P ${DATABASE_PORT} -p${DATABASE_MASTER_PASSWORD}
