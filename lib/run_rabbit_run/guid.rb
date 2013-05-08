module RunRabbitRun
  module Guid
    extend self

    def remove
      File.delete(path) if File.exists?(path)
    end

    def guid
      @guid || _guid 
    end

  private

    def save(guid)
      create_directory_if_not_exists(File.dirname(path))

      File.open(path, "w") {|file| file.puts(guid) }
    end

    def _guid
      @guid = File.open(path, 'r') { |file| file.read }.strip if File.exists?(path)
      unless @guid
        @guid = SecureRandom.uuid.gsub(/[^A-za-z0-9]/,"")
        save(@guid)
      end

      @guid
    end 

    def path
      raise "[ERROR] please specify the guid file path" unless RunRabbitRun.config[:guid]

      RunRabbitRun.config[:guid]
    end

    def create_directory_if_not_exists(dir)
      FileUtils.mkdir_p(dir) unless File.exists?(dir)
    end

  end
end

