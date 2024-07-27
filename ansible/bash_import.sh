#!/bin/bash

# Remote database credentials
ENV="dev"
APP_NAME="app1"

ALB_DNS=$(aws ssm get-parameter --name "/$ENV/alb-$APP_NAME/dns" --with-decryption --query "Parameter.Value" --output text)
DB_PASS=$(aws ssm get-parameter --name "/$ENV/db-$APP_NAME/password" --with-decryption --query "Parameter.Value" --output text)
DB_USER=$(aws ssm get-parameter --name "/$ENV/db-$APP_NAME/username" --with-decryption --query "Parameter.Value" --output text)
DB_HOST=$(aws ssm get-parameter --name "/$ENV/db-$APP_NAME/url" --with-decryption --query "Parameter.Value" --output text)
DB_NAME=$(aws ssm get-parameter --name "/$ENV/db-$APP_NAME/name" --with-decryption --query "Parameter.Value" --output text)
DB_PORT=3306

# Path to the SQL dump file
SQL_DUMP="wordpress.sql"

# Check if the SQL dump file exists
if [ ! -f "$SQL_DUMP" ]; then
    echo "Error: SQL dump file not found: $SQL_DUMP"
    exit 1
fi

# Replace occurrences of 'localhost' with 'ALB URL' in the dump file
sed -i "s/localhost/$ALB_URL/g" "$SQL_DUMP"

# Log in to MySQL/MariaDB on the remote server and restore the database
mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" < "$SQL_DUMP"

# Check the exit status of the mysql command
if [ $? -eq 0 ]; then
    echo "Database restored successfully."
else
    echo "Error: Database restore failed."
fi