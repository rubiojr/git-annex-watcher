require 'yaml'

module GAW 

  class Settings

    def initialize(yaml = {})
      @settings = yaml
    end

    def self.config_dir
      dir = "#{ENV['HOME']}/.config/git-annex-watch"
    end

    def save
      dir = Settings.config_dir
      unless File.directory?(dir)
        Log.debug "Creating settings directory: #{dir}"
        Dir.mkdir dir 
      end
      Log.debug "Saving settings to #{File.join(dir,'settings.yaml')}"
      File.open(File.join(dir,"settings.yaml"), 'w') do |f|
        f.puts @settings.to_yaml
      end
    end
    
    def [](key)
      @settings[key]
    end

    def []=(key, val)
      @settings[key] = val
    end
    
    def each(&block)
      @settings.each &block
    end

    def self.load
      return @@instance if defined? @@instance
      Log.debug "Loading settings from #{config_dir}/settings.yaml"
      file = "#{config_dir}/settings.yaml"
      if File.exist? file
        begin
          @@instance = Settings.new YAML.load_file(file)
        rescue TypeError
          # if the yaml file is empty, 1.9.3p194 raises TypeError
          @@instance = Settings.new
        rescue Exception => e
          Log.error "Error loading settings: #{e}\n#{e.backtrace}"
        end
      else
        @@instance = Settings.new
      end
      @@instance
    end

  end

end
