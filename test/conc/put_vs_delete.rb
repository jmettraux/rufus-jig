
$:.unshift('lib')

require 'patron'
require 'yajl'
require 'rufus/jig'

C0 =  Rufus::Jig::Couch.new('127.0.0.1', 5984, 'test0', :re_put_ok => false)
C1 =  Rufus::Jig::Couch.new('127.0.0.1', 5984, 'test0', :re_put_ok => false)

d = C0.get('nada')
C0.delete(d) if d

C0.put({ '_id' => 'nada', 'where' => 'London' })
d = C0.get('nada')

t1 = Thread.new do
  p [ Thread.current.object_id, :delete, d['_rev'], C1.delete(d) ]
end
t0 = Thread.new do
  p [ Thread.current.object_id, :put, d['_rev'], C0.put(d) ]
end

sleep 0.500

p C0.get('nada')
p C1.get('nada')

