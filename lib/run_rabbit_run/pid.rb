module RunRabbitRun
  module Pid
    extend self

    def remove
      File.delete(path) if File.exists?(path)
    end

    def pid
      File.open(path, 'r') { |file| file.read }.to_i if File.exists?(path)
    end

    def save(pid)
      create_directory_if_not_exists(File.dirname(path))

      File.open(path, "w") {|file| file.puts(pid) }
    end

  private 

    def path
      raise "[ERROR] please specify the pid file path" unless RunRabbitRun.config[:pid]

      RunRabbitRun.config[:pid]
    end

    def create_directory_if_not_exists(dir)
      FileUtils.mkdir_p(dir) unless File.exists?(dir)
    end

  end
end
