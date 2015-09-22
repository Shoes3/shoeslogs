#!/usr/bin/env ruby
# Count the unique shoes generated queries 
require 'sqlite3'
here = Dir.getwd
dbfile = File.join(here, 'sitelog.db')
iphash = {}
pathhash = {}
db = SQLite3::Database.new dbfile
rows = db.execute "select * from access_lines where user_agent='Ruby'"
rows.each do |idx,rid,sid,lineno,ip,logname, user, dt,verb,path,ver,st,sz,ref,br| 
  if iphash[ip] 
    iphash[ip] = iphash[ip]+1
  else 
    iphash[ip] = 1
  end
  if pathhash[path]
    pathhash[path] = pathhash[path]+1
  else
    pathhash[path] = 1
  end
end
iphash.each {|k,v| puts "#{k} accessed #{v} times"}
pathhash.each {|k,v| puts "#{k} cnt #{v}"}
puts "Unique IP's #{iphash.length} Total: #{rows.length}"
# create/append a file with full path and status = 'likely'
uf = File.open("users.txt",'a')
rows.each do |idx,rid,sid,lineno,ip,logname, user, dt,verb,path,ver,st,sz,ref,br|
  uf.puts "#{ip}|pack|#{path}|#{dt}"
end
uf.close
