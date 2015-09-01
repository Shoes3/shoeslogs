#!/usr/bin/env ruby
# Count the unique shoes generated queries 
require 'sqlite3'
here = Dir.getwd
dbfile = File.join(here, 'sitelog.db')
iphash = {}
pathhash = {}
brhash = {}
shoeshash = {}
shoeslst = []
maybeOK = []
hackers = []
white = []
partial = {}  # tricky if their browser chunks the download
db = SQLite3::Database.new dbfile
rows = db.execute "select * from access_lines"
rows.each do |idx,rid,sid,lineno,ip,logname, user, dt,verb,path,ver,st,sz,ref,br|
  # positive things first? 
  if  br =~ /^(Ruby|Shoes)/
    # our friends! 
    if shoeshash[ip]
      shoeshash[ip] = shoeshash[ip]+1
    else 
      shoeshash[ip] = 1
    end
    shoeslst << [ip, path, dt, ref, br]
    next
  end
  if path =~ /\/public\/shoes\/shoes-3.2/ && st == 200
    if sz.to_i < 10000000 #10MB Partial download? 
      key = ip+'|'+path
      if !partial[key]
        partial[key] = [sz.to_i, [dt, ref, br]]
      else
        ary = partial[key]
        ary[0] += sz.to_i
        ary[1] = [dt, ref, br]
        partial[key] = ary
      end
      next
    end
    if iphash[ip]
      iphash[ip] = iphash[ip]+1
    else 
      iphash[ip] = 1
    end
    if pathhash[ip]
      pathhash[path] = pathhash[path]+1
      maybeOK << [ip, path, dt, ref, br]
    else
      pathhash[path] = 1
      maybeOK << [ip, path, dt, ref, br]
    end
    if brhash[br]
      brhash[br] = brhash[br]+1
    else
      brhash[br] = 1
    end
  elsif verb == 'POST' || verb == 'PUT' || path =~/\.php/
    hackers <<  [ip, path, dt, ref, br]
  end
end
# successful partials could add up to one download, so lets count them as one
# if possible. Sampling suggests China and RIPE and old browsers for Windows.
# Some of them might be legitimate. Hey, it's possible!?!
dumbass = []
partial.each do |k, val| 
  flds = k.split('|')
  ip = flds[0]
  path = flds[1]
  # val is an array [sz, [dt,ref,br]]
  len = val[0]
  ary = val[1]
  dt = ary[0]
  ref = ary[1]
  br = ary[2]
  if len < 10000000 || len > 35000000  # at least one, maybe two dowloads
    dumbass << [ip, path, dt, ref, br]
  else 
    maybeOK << [ip, path, dt, ref, br]
  end
end
# append summary to this file:
uf = File.open("users.txt",'a')
puts "Hackers: "
hackers.each {|ent| puts "    #{ent}"}
hackers.each {|ent| uf.puts "#{ent[0]}|hacker|#{ent[1]}|#{ent[2]}|#{ent[3]}|#{ent[4]}"}
# Good guys
puts "Shoes users: #{shoeslst.length}"
shoeshash.each {|k,v| puts "  #{k} cnt #{v}"} 
shoeslst.each {|ent| uf.puts "#{ent[0]}|shoes|#{ent[1]}|#{ent[2]}|#{ent[3]}|#{ent[4]}"}

puts "Maybe OK downloads:"
maybeOK.each {|ent| puts "    #{ent[0]}, #{ent[1]}"}
maybeOK.each {|ent| uf.puts "#{ent[0]}|maybe|#{ent[1]}|#{ent[2]}|#{ent[3]}|#{ent[4]}"}
puts "Very iffy - consider blocking"
dumbass.each {|ent| puts "    #{ent[0]} suspicious  #{ent[1]}"}
dumbass.each {|ent| uf.puts "#{ent[0]}|iffy|#{ent[1]}|#{ent[2]}|#{ent[3]}|#{ent[4]}"}
uf.close
