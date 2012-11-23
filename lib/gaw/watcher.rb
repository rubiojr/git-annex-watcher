# encoding: utf-8
require 'rb-inotify'
require 'gtk2'
require 'gaw/resources'
require 'gaw/threading_hack'
require 'gaw/notify'
require 'thread'

module GAW

  #
  # StatusIcon
  # http://ruby-gnome2.sourceforge.jp/hiki.cgi?Gtk%3A%3AStatusIcon
  #
  class WatcherIcon

    def initialize
      @queue = Queue.new
      @icon = Gtk::StatusIcon.new
      @off_icon = Gdk::Pixbuf.new(GAW::Resources.get_icon('git-annex-tray-off.svg'))
      @icon.pixbuf = @off_icon
      @icon.tooltip ='Git Annex'
      @send_animation = []
      @settings = Settings.load

      # 
      # Send files animation
      #
      @frames = {}
      @frames[:send] = []
      1.upto(4) do |i| 
        icon = GAW::Resources.get_icon("git-annex-tray#{i}.svg")
        @frames[:send]<< Gdk::Pixbuf.new(icon)
      end

      # 
      # Receive files animation
      #
      @frames[:receive] = []
      1.upto(4) do |i| 
        icon = GAW::Resources.get_icon("git-annex-tray-rcv-#{i}.svg")
        @frames[:receive] << Gdk::Pixbuf.new(icon)
      end

      #
      # Other events animation
      #
      @frames[:other]= []
      1.upto(4) do |i| 
        icon = GAW::Resources.get_icon("git-annex-tray-other-#{i}.svg")
        @frames[:other] << Gdk::Pixbuf.new(icon)
      end
      @add_dialog = nil
      create_menues
    end

    def start
      @thread = Thread.start do
        loop do
          etype = @queue.pop
          animate @frames[etype]
          if @queue.empty? 
            Gtk.queue do
              Log.debug 'Stop status icon animation'
              @icon.pixbuf = @off_icon 
            end
          end
        end
      end
    end

    def queue_send
      # We want to keep the queue small
      return if @queue.size >= 10
      Log.debug 'enqueing "send" event...'
      @queue << :send
    end

    def queue_recv
      # We want to keep the queue small
      return if @queue.size >= 10
      Log.debug 'enqueing "recv" event...'
      @queue << :receive
    end

    def queue_other
      # Do not enqueue other events if sending/receiving
      return unless @queue.empty? or (@queue.size <= 1)
      Log.debug 'enqueing "other" event...'
      @queue << :other
    end

    private
    def animate(frames)
      #2.times do
        1.upto(4) do |i|
          sleep 0.3
          Gtk.queue do
            @icon.pixbuf = frames[i - 1]
          end
        end
      #end
    end

    def save_new_annex(path)
      # Create the menu item
      Log.debug "Adding menu item"
      real_path = path.gsub('/.git/annex', '')
      name = real_path.split('/').last
      label = "<b>#{name.capitalize}</b>"
      item = Gtk::ImageMenuItem.new(Gtk::Stock::DIRECTORY)
      item.child.set_markup "#{label}\n#{real_path}"
      item.signal_connect('activate') do |item|
        target = item.child.label.split.last
        `/usr/bin/x-terminal-emulator --working-directory=#{target}`
      end
      @status_menu.append(item)
      @status_menu.show_all
    end
    
    def create_menues 
      ###**************************###
      ## Pop up menu on rigth click
      ###**************************###
      ##Build a menu
      @info = Gtk::ImageMenuItem.new(Gtk::Stock::INFO)
      @info.signal_connect('activate'){ }
      @about = Gtk::ImageMenuItem.new(Gtk::Stock::ABOUT)
      @about.signal_connect('activate') do
        d = Gtk::AboutDialog.new
        d.name = 'Git Annex Watcher'
        d.version = GAW::VERSION
        d.logo_icon_name = 'git-annex-watcher'
        d.copyright = '© 2012 Sergio Rubio'
        d.comments = "Desktop Status Icon for Git Annex"
        d.website = "http://gaw.frameos.org"
        d.authors = ["Sergio Rubio <rubiojr@frameos.org>"]
        d.artists = ['The Open Icon Library Project: http://openiconlibrary.sourceforge.net']
        d.program_name = 'Git Annex Watcher'
        d.signal_connect('response') { d.destroy }
        d.run
      end
      @quit= Gtk::ImageMenuItem.new(Gtk::Stock::QUIT)
      @quit.signal_connect('activate'){ Gtk.main_quit }
      @menu = Gtk::Menu.new
      @menu.append(@info)
      @menu.append(@about)
      @menu.append(@quit)
      @menu.show_all
      ##Show menu on rigth click
      #@icon.signal_connect('popup-menu'){|tray, button, time| @menu.popup(nil, nil, button, time)}

      ###**************************###
      ## Pop up menu on left click
      ###**************************###
      ##Build a menu
      @status_menu = Gtk::Menu.new
      @add_mi = Gtk::ImageMenuItem.new(Gtk::Stock::ADD)
      @add_mi.label = "Add repository"
      @add_mi.signal_connect('activate'){ add_new_annex }
      @status_menu.append(@add_mi)
      @status_menu.append(Gtk::SeparatorMenuItem.new)
      @status_menu.show_all
      Settings.load.each do |k,v|
        save_new_annex v['path']
      end
      @icon.signal_connect('button_press_event') do |widget, event|
        if event.button == 1
          @status_menu.popup(nil, nil, event.button, event.time) do
            @icon.position_menu(@status_menu)
          end
        elsif event.button == 3
          @menu.popup(nil, nil, event.button, event.time) do
            @icon.position_menu(@status_menu)
          end
        else
        end
      end
    end

    #
    # right-click -> add repository
    #
    def add_new_annex
      return if @add_dialog
      @add_dialog = Gtk::FileChooserDialog.new("Open File",
                                           nil,
                                           Gtk::FileChooser::ACTION_SELECT_FOLDER,
                                           nil,
                                           [Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_CANCEL],
                                           [Gtk::Stock::OPEN, Gtk::Dialog::RESPONSE_ACCEPT]) 

      dir = nil
      if @add_dialog.run == Gtk::Dialog::RESPONSE_ACCEPT 
        dir = @add_dialog.filename
        if File.directory?(dir + "/.git/annex")
          Log.info "Adding new annex: #{dir}"
          patched_dir = dir + "/.git/annex"
          watcher = Watcher.new patched_dir, @icon
          ga_uuid = UUIDTools::UUID.md5_create(UUIDTools::UUID_DNS_NAMESPACE, patched_dir).to_s
          Log.debug "Annex UUID #{ga_uuid}"
          unless @settings[ga_uuid]
            @settings[ga_uuid] = {}
            @settings[ga_uuid]['path'] = patched_dir
            @settings.save
          end
          save_new_annex patched_dir

          Notify.send 'Repository added',"<b>#{dir}</b>", 'user-home'
        else
          Log.info "Invalid repository #{dir}. '.git/annex' directory not found."
        end
      end
      @add_dialog.destroy
      @add_dialog = nil
    end

  end

  class Watcher

    attr_accessor :status
    attr_reader   :opened_files

    def initialize(dir, icon)
      @watcher = INotify::Notifier.new
      @regexp = Regexp.new /(transfer\/(upload|download))|tmp|ssh/
      @watcher.watch(dir, :recursive, :modify, :access, :close, :open) do |event|
        Log.debug "Receiving inotify event: #{event.absolute_name}"
        next unless event.absolute_name =~ @regexp
        next if File.directory? event.absolute_name 
        if event.absolute_name =~ /upload/
          icon.queue_send
        elsif event.absolute_name =~ /download/
          icon.queue_recv
        else
          icon.queue_other
        end
      end
      @thread = Thread.start do
        @watcher.run
      end
    end

  end

end
