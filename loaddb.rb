#!/usr/bin/env ruby
# load one file (ARGV[0]) into the database.
here = Dir.getwd
dbfile = File.join(here, 'sitelog.db')
if File.exists? dbfile
  File.delete dbfile
end
`request-log-analyzer --silent -d  #{dbfile} #{ARGV[0]}`
