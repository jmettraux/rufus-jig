
module CouchHelper

  def couch_url

    File.readlines(
      File.join(File.dirname(__FILE__), '../couch_url.txt')
    ).find { |line|
      line = line.strip
      line.match(/^http/)
    }
  end
end

