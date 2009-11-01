
begin
  Rufus::Jig::Http.new('127.0.0.1', 5984).get('/_all_dbs')
rescue Exception => e
  p e
  puts
  puts "couch not running..."
  puts
  exit(1)
end

