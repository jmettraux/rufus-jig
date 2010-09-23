
$:.unshift('lib')
require 'benchmark'
require 'patron'
require 'yajl'
require 'rufus/jig'

N = 1

DOC = {}
1000.times { |i| DOC["key#{i}"] = { 'a' => 'b', 'c' => 'd', 'e' =>'f' } }

Rufus::Jig::Couch.delete_db('http://127.0.0.1:5984/test_bm0') rescue nil
CDB = Rufus::Jig::Couch.put_db('http://127.0.0.1:5984/test_bm0')

Benchmark.benchmark(' ' * 31 + Benchmark::Tms::CAPTION, 31) do |b|

  b.report('marshal to file') do
    N.times do
      File.open('out.marshal', 'wb') { |f| f.write(Marshal.dump(DOC)) }
    end
  end
  b.report('yajl to file') do
    N.times do
      File.open('out.json', 'wb') { |f| f.write(Rufus::Jig::Json.encode(DOC)) }
    end
  end
  b.report('to couch') do
    N.times do |i|
      CDB.put_doc("out#{i}", DOC)
    end
  end

  b.report('marshal from file') do
    N.times do
      doc = Marshal.load(File.read('out.marshal'))
    end
  end
  b.report('yajl from file') do
    N.times do
      doc = Rufus::Jig::Json.decode(File.read('out.json'))
    end
  end
  b.report('from couch') do
    N.times do |i|
      doc = CDB.get_doc("out#{i}")
    end
  end
end
