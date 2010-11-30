
module ServerHelper

  def fork_server

    server = File.expand_path(
      File.join(File.dirname(__FILE__), '..', 'server.rb'))

    $SERVER = Process.fork do
      exec "ruby #{server} > server.log 2>&1"
    end

    sleep 1.0

    $SERVER
  end

  def purge_server

    Rufus::Jig::Http.new('127.0.0.1', 4567).delete('/documents') rescue nil
  end

  def kill_server

    Process.kill(9, $SERVER) #rescue nil
    $SERVER = nil

    nil
  end
end

