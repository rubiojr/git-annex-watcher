module GAW
  class Notify

    def self.send(summary, body = nil, icon = nil)
      unless File.exist?('/usr/bin/notify-send')
        Log.error "/usr/bin/notify-send not found"
        Log.error "Desktop notifications will not work"
      end
      args = []
      args << "'#{body}'" if body
      args << "-i #{icon}" if icon
      out = `/usr/bin/notify-send '#{summary}' #{args.join(' ')} 2>&1`
      Log.debug "Sending desktop notification: #{summary} #{args.join(' ')}"
    end
  end
end
