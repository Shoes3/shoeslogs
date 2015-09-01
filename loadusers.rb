#!/usr/bin/env ruby
# parse users.txt, insert into users.db
# move users.txt to history/users.YYYMMDD
# if ARGV[0] is given use that instead of 'users.txt' and don't move files
# unless ARGV[0] is '-k', don't move users.txt but copy it (used for testing this script.
require 'sqlite3'
require 'fileutils'
include FileUtils
# sqlite3 needs an ABS path?
here = Dir.getwd
dbfile = File.join(here, 'users.db')
db = SQLite3::Database.new dbfile
infn = File.join(here, 'users.txt')
movefile = true
if ARGV[0]
  if ARGV[0]=='-k'
    movefile = false
  else
    infn = ARGV[0]
    movefile = false
  end
end
# open the input, parse,insert into db and close 
inf = File.open(infn)
inf.each do |ln| 
  flds = ln.split('|')
  ip = flds[0]
  cat = flds[1]
  path = flds[2]
  dt = flds[3].strip
  ref = flds[4].strip
  br = flds[5].strip
  
  next if ip=='96.18.0.73'  # TODO can we get this from Ruby or inux?  DHCP  will change over time
  # we only track one ip in user table - OR IGNORE does that. Who knew that option existed?
  # activity counter will be updated below
  userinsert = "INSERT OR IGNORE INTO users (ip, type, activity, mod_date) values (\"#{ip}\",\"#{cat}\",0,#{dt})"
  db.execute(userinsert)
  # now do the downloads table + wacky heuristics. Pay attention.
  basename = File.basename(path)
  if cat=='hacker'
    # just insert the minimal 
    hackstr = "INSERT INTO downloads(userip, ptype, reqdate, path)\
      values (\"#{ip}\", 'E', #{dt}, \"#{path}\")"
    db.execute(hackstr)
  elsif basename =~ /\.rb$/
    # TODO: modify their status in users table (if they exist). 
    nicestr = "INSERT INTO downloads(userip, ptype, reqdate, path)\
      values (\"#{ip}\", 'P', #{dt}, \"#{path}\")"
    db.execute(nicestr)
  else 
    # demo: when naming conventions fail:
    pflds = basename.split('-')
    if pflds[0] != 'shoes' && pflds[0] != 'Shoes'
      puts "Not shoes #{basename} #{pflds[0]}"  # expect some (shoesdeps.zip ...?)
      next
    end
    if flds.length != 6
     puts "what is this?: #{ln}"
     next
    end
    ver = pflds[1]
    gui = pflds[2]
    if gui == 'osx'
      osxtmp = pflds[3].split('.')
      arch = "#{osxtmp[0]}.#{osxtmp[1]}"
    else
      arch = pflds[3].split('.')[0]
    end
    arch= 'w32' if arch=='32'
    dnlstr = "INSERT INTO downloads (userip,ptype,version,gui,arch,reqdate,path,refer,browser)\
      values (\"#{ip}\", 'D', \"#{ver}\",\"#{gui}\",\"#{arch}\",#{dt},\"#{path}\",\'#{ref}\',\'#{br}\')"
    db.execute(dnlstr)
  end
  # update the users.activity counter - gruesome or just ugly?
  updaterow = db.execute("SELECT activity FROM users WHERE ip = \"#{ip}\"")
  # yes it is [[n]] - I'd call it gruesome.
  db.execute("UPDATE users SET activity = #{updaterow[0][0].to_i+1} WHERE ip = \"#{ip}\"")
 
end
inf.close
db.close
#
# move  or copy file 
savedir = File.join(here, 'data')
mkdir_p File.join(savedir)
ymd = Time.now.strftime("%Y%m%d")
outfn = File.join(savedir, "users.#{ymd}")
if movefile 
  puts "move to #{outfn}"
  mv infn, outfn
else
  puts "copy to #{outfn}"
  cp infn, outfn
end
