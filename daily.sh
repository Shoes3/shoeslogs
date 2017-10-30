#!/bin/bash
# daily.sh downloads the access.log.0 and feeds it into the db.
# Dreamhost schedule suggests after 3:00 AM (PST)
echo "/n==== Get log ====/n"
cd /home/ccoupe/Projects/shoeslogs
source ~/.rvm/scripts/rvm
rvm use 2.1.6
sftp site:logs/shoes.mvmanila.com/http/access.log.0
mv access.log.0 http.log
sftp site:logs/shoes.mvmanila.com/https/access.log.0
mv access.log.0 https.log
cat http.log https.log >>access.log.0
echo "/n===== Load Log ====/n"
./loaddb.rb access.log.0 
#./shoesusers.rb
echo "/n==== Process Log > users.txt ====/n"
./downloads.rb
echo "/n==== Load users.db ====/n"
./loadusers.rb 
echo "/n===== Maintain Log DB ====/n"
./processusers.rb
