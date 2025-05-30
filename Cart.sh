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

dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "Nodejs disabled"

dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "Nodejs enabled"

dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "Nodejs installation"

id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]
then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    VALIDATE $? "Creating roboshop system user"
else
    echo -e "System user roboshop already created ... $Y SKIPPING $N"
fi

rm -rf /app/*
mkdir -p /app 
curl -L -o /tmp/cart.zip https://roboshop-artifacts.s3.amazonaws.com/cart-v3.zip &>>$LOG_FILE
cd /app 
unzip /tmp/cart.zip &>>$LOG_FILE
VALIDATE $? "Created the app directory and downloaded the source code and pasted in it"

cd /app 
npm install &>>$LOG_FILE
VALIDATE $? "npm installing the dependencies"

cp $SCRIPT_DIR/Cart.service /etc/systemd/system/cart.service 
VALIDATE $? "Service file configuration"

systemctl daemon-reload &>>$LOG_FILE
systemctl enable cart &>>$LOG_FILE
systemctl start cart &>>$LOG_FILE
VALIDATE $? "Cart service starting"










