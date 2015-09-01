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
# todaysips.each {|k,v| puts "Today has #{k}"}

# so many ways to find oddities. Here's one of many
oddsql = "select users.type, downloads.* from downloads, users where ptype != 'P' and refer='' and browser != 'Ruby' and users.ip = userip"
# There are others: maybe/iffys should not have large activity values;
iffysql = "select * from users where type IN ('iffy','maybe') and activity>3"
rows = db.execute(iffysql)
rows.each do |ip,type,cnt,dt|
  if todaysips[ip]
    db.execute("INSERT INTO flagged (flagip, flagdate) VALUES (\"#{ip}\",#{dt})")
  end
end
