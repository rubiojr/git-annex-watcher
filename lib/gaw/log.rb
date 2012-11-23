require 'logger'

module GAW

  if !defined? Log or Log.nil?
    Log = Logger.new($stdout)
    Log.formatter = proc do |severity, datetime, progname, msg|
      if severity == "INFO"
        "* #{msg}\n"
      else
        "* #{severity}: #{msg}\n"
      end
    end
    Log.level = Logger::INFO unless (ENV["DEBUG"].eql? "yes" or ENV["DEBUG"].eql? 'true')
    Log.debug "Initializing logger"
  end

end
