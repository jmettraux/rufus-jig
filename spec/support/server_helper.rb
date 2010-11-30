
module ServerHelper

  def purge_server

    Rufus::Jig::Http.new('127.0.0.1', 4567).delete('/documents') rescue nil
  end

  def self.fork_server

    server = File.expand_path(
      File.join(File.dirname(__FILE__), '..', 'server.rb'))

    $server = Process.fork do
      exec 'ruby', server
    end

    sleep 1.0

    $server
  end

  def self.kill_server

    Process.kill('SIGINT', $server) #rescue nil
    Process.wait($server)
    $server = nil

    nil
  end
end

