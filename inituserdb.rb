#!/usr/bin/env ruby
# create sitelog.db
require 'sqlite3'
require 'fileutils'
# sqlite3 needs an ABS path?
here = Dir.getwd
dbfile = File.join(here, 'users.db')
if File.exists? dbfile
  File.delete dbfile
end
db = SQLite3::Database.new dbfile
userstr =  "create table users (\
  ip CHAR(15) PRIMARY KEY NOT NULL,\
  type CHAR(6) NOT NULL,\
  activity INTEGER,\
  mod_date DATETIME NOT NULL\
  )"
db.execute userstr
dnloadstr = "create table downloads (\
  id INTEGER PRIMARY KEY,\
  userip CHAR(15) NOT NULL,\
  ptype CHAR(1) NOT NULL,\
  version CHAR(7),\
  gui  CHAR(4),\
  arch VARCHAR(10),\
  reqdate DATETIME,\
  path VARCHAR(64)\,
  refer VARCHAR(64),\
  browser VARCHAR(64)\
  )"
db.execute dnloadstr
flaggedstr = "create table flagged (\
  id INTEGER PRIMARY KEY,\
  flagip CHAR(15) NOT NULL,\
  flagdate DATETIME\
  )"
db.execute(flaggedstr)


db.execute("CREATE INDEX index_downloads ON downloads (userip)")
db.execute("CREATE INDEX index_flagged ON flagged (flagip)")
