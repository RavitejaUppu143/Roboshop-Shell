#!/bin/bash

START_TIME=$(date +%s)
USER_ID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[97m"
LOG_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOG_FOLDER/$SCRIPT_NAME"
SCRIPT_DIR=$PWD

mkdir -p $LOG_FOLDER
echo "Script started executing at: $(date)" | tee -a $LOG_FILE

# Checks if the user is root user or not
if [ $USER_ID -ne 0 ]
then
echo -e "$R ERROR:: Please run this script with root access $N" | tee -a $LOG_FILE
exit 1
else
echo "You are running with root access" | tee -a $LOG_FILE
fi


# Validate if the given command is successfull or not
VALIDATE(){
    if [ $1 -eq 0 ]
    then
        echo -e "$2 is ... $G SUCCESS $N" | tee -a $LOG_FILE
    else
        echo -e "$2 is ... $R FAILURE $N" | tee -a $LOG_FILE
        exit 1
    fi
}

dnf install maven -y &>>$LOG_FILE
VALIDATE $? "Maven is installation"

id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]
then
useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
VALIDATE $? "Robshop user creation"
else
echo "Roboshop user is already created......$Y SKIPPING $N" | tee -a $LOG_FILE
fi

rm -rf /app/*
mkdir -p /app 
curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>>$LOG_FILE
cd /app 
unzip /tmp/shipping.zip &>>$LOG_FILE
VALIDATE $? "Created the app directory and downloaded the source code and pasted in it"



cd /app 
mvn clean package &>>$LOG_FILE
VALIDATE $? "Installing dependencies"

mv target/shipping-1.0.jar shipping.jar &>>$LOG_FILE
VALIDATE $? "Moving shipping.jar file to app director"

cp $SCRIPT_DIR/Shipping.service /etc/systemd/system/shipping.service &>>$LOG_FILE
VALIDATE $? "Service file configuration"


systemctl daemon-reload &>>$LOG_FILE
systemctl enable shipping &>>$LOG_FILE
systemctl start shipping &>>$LOG_FILE
VALIDATE $? "Shipping service starting"


dnf install mysql -y &>>$LOG_FILE
VALIDATE $? "Mysql client installation"

mysql -h mysql.daws84s.site -uroot -pRoboShop@1 -e 'use cities' &>>$LOG_FILE
if [ $? -ne 0 ]
then
    mysql -h mysql.daws84s.site -uroot -pRoboShop@1 < /app/db/schema.sql &>>$LOG_FILE
    mysql -h mysql.daws84s.site -uroot -pRoboShop@1 < /app/db/app-user.sql  &>>$LOG_FILE
    mysql -h mysql.daws84s.site -uroot -pRoboShop@1 < /app/db/master-data.sql &>>$LOG_FILE
    VALIDATE $? "Loading data into MySQL"
else
    echo -e "Data is already loaded into MySQL ... $Y SKIPPING $N"
fi

systemctl restart shipping &>>$LOG_FILE
VALIDATE $? "Restart shipping"


END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))

echo -e "Script exection completed successfully, $Y time taken: $TOTAL_TIME seconds $N" | tee -a $LOG_FILE