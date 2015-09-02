#!/usr/bin/env ruby
require 'sqlite3'
require 'fileutils'
include FileUtils
here = Dir.getwd
dbfile = File.join(here, 'users.db')
db = SQLite3::Database.new dbfile
# Build a very suspicious list of ip with some SQL queries
# But we only want to process todays data (which is in sitelog.db
# which has an index on reguest_host. Yes it going to get weird.
tdb = SQLite3::Database.new(File.join(here,'sitelog.db'))
todaysips = {}
trows = tdb.execute("select remote_host from access_lines")
trows.each {|ip| 
  todaysips[ip[0]] = true #[0] because its sql. don't fight it. gemiliscous
}
tdb.close

todays_catch = []

# so many ways to find oddities.
# There are others: maybe/iffys should not have large activity values;
iffysql = "SELECT * FROM users WHERE type IN ('iffy','maybe') AND activity>3"
rows = db.execute(iffysql)
rows.each do |ip,type,cnt,dt|
  if todaysips[ip]
    todays_catch << ip
    db.execute("INSERT OR IGNORE INTO flagged (flagip, flagdate) VALUES (\"#{ip}\",#{dt})")
  end
end
# Catch those who don't have refer - it's either a leech, bot-experiment, 
# or sometimes it's Shoes (packaging related)
refsql = "select users.type, downloads.* from downloads, users where ptype != 'P'\
 and refer='' and (browser != 'Ruby' AND browser NOT Like 'Shoes%') and users.ip = userip"
rows = db.execute(refsql)
rows.each do |type,idx,ip,ptype,version,gui,arch,reqdate,path,refer,browser|
  if todaysips[ip]
    todays_catch << ip
    db.execute("INSERT OR IGNORE INTO flagged (flagip, flagdate) VALUES (\"#{ip}\",#{reqdate})")
  end
end
puts "/n== Todays Catch in flagged table ==/n"
todays_catch.sort.each {|ip| puts "  #{ip}"}
