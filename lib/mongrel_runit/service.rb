#  Created by Adam Jacob on 2007-03-21.
#  Copyright (c) 2007. All rights reserved.

require 'mongrel_runit/base'

module MongrelRunit
  
  # Represents a runit service directory for a particular mongrel.
  # 
  # Example:
  # 
  #   service = MongrelRunit::Service.new(config)
  #   service.stop
  #   service.start
  #   service.create
  #
  
  class Service < Base
    attr_reader :runfile, :logrunfile, :logconfig, :checkfile, :svdir, :config
    
    # Takes a configuration hash as it's argument, ensures the 
    # runit_service_dir exists, and creates the runit_sv_dir.
    def initialize(config)
      @config = config
      
      raise ArgumentError, "Must have an application_name!" unless @config.has_key?("application_name")
      raise ArgumentError, "Must have a port!" unless @config.has_key?("port")
      raise ArgumentError, "Must have a runit_sv_dir!" unless @config.has_key?("runit_sv_dir")
      raise ArgumentError, "Must have a runit_service_dir!" unless @config.has_key?("runit_service_dir")
      
      check_service_dir
      make_sv_dir 
    end
    
    # Catch-all for the common service commands.  See MongrelRunit::Base for 
    # a list.
    def method_missing(status)
      if self.has_command?(status.id2name)
        run(status.id2name)
      else
        Kernel.method_missing
      end
    end
    
    # Returns true if the process is running, nil if it's not.
    def is_running? 
      output, success = run("status")
      output =~ /^run:/ ? true : nil
    end
    
    # Run a given command through sv.
    def run(status)
      cmd = "sv "
      cmd += " -w #{@config['svwait']}" if @config.has_key?('svwait')
      cmd += " #{status} #{@svdir}"
      output = `#{cmd}`
      return output, $?.success?
    end
    
    # Create the service directory for this mongrel.  This includes the
    # run script, log script, check script, and log config file.  This
    # should run any time there is a change to the configruation.
    def create
      make_run
      make_check
      make_log
      make_log_config
      link = make_service_link
      return link, true
    end
    
    # Raises an exception if the runit_service_dir does not exist.
    def check_service_dir
      dir_exists = File.directory?(@config["runit_service_dir"])
      raise ArgumentError, "runit_service_dir does not exist: #{@config["runit_service_dir"]}" unless dir_exists
      dir_exists
    end
    
    # Creates the symlink between the mongrel's sv directory and the
    # runit_service_dir.
    def make_service_link
      servicename = File.basename(@svdir)
      link = File.expand_path(File.join(@config["runit_service_dir"], servicename))
      unless File.symlink?(link)
        `ln -s #{@svdir} #{@config["runit_service_dir"]}`
      end
      link
    end
    
    # Populates the check file, either with the contents of the checkfile
    # configuration option, or:
    #
    #   #!/usr/bin/env ruby
    #
    #   require 'net/http'
    #
    #   http = Net::HTTP.new('#{address}', #{@config["port"].to_i})
    #   begin
    #    response = http.options('/')
    #    if response = Net::HTTPSuccess
    #      exit 0
    #    else 
    #      exit 1
    #    end
    #  rescue Errno::ECONNREFUSED
    #    exit 1
    #  end
    def make_check
      if @config.has_key?("checkfile") 
        @checkfile = interpret_line(@config["checkfile"])
      else
        @checkfile = <<EOH
#!/usr/bin/env ruby

require 'net/http'

http = Net::HTTP.new('#{@config['address']}', #{@config["port"].to_i})
begin
  response = http.options('/')
  if response = Net::HTTPSuccess
    exit 0
  else 
    exit 1
  end
rescue Errno::ECONNREFUSED
  exit 1
end
EOH
      end
      path_to_checkfile = File.expand_path(File.join(@svdir, "check"))
      create_or_update_file(path_to_checkfile, @checkfile)
      File.chmod(0755, path_to_checkfile)
      path_to_checkfile
    end
    
    # Creates the sv direrectory for this mongrel. (From runit_sv_dir)
    def make_sv_dir
      @svdir = File.expand_path(File.join(
        @config["runit_sv_dir"],
        "mongrel-#{@config["application_name"]}-#{@config["port"]}"
      ))
      @svlogdir = File.expand_path(File.join(
        @svdir, "log"
      ))
      `mkdir -p #{@svlogdir}`
      raise "Cannot create #{@svlogdir}" unless $?.success?
      @svlogdir
    end
    
    # If svlogd_config is defined, creates the log config file.
    def make_log_config
      path_to_file = nil
      if @config.has_key?("svlogd_config")
        path_to_file = File.expand_path(File.join(@svlogdir, "config"))
        @logconfig = @config["svlogd_config"]
        create_or_update_file(path_to_file, @logconfig)
      end
      path_to_file
    end
    
    # Makes the log run script.
    def make_log
      logdir = File.expand_path(File.join(@svlogdir, "main"))
      if @config.has_key?("base_log_directory")
        logdir = File.expand_path(File.join(
          @config["base_log_directory"], 
          "#{@config[application_name]}-#{@config[port]}"
        ))
      end
      `mkdir -p #{logdir}`
      raise "Cannot create #{logdir}" unless $?.success?
      @logrunfile =  "#!/bin/sh\n"
      @logrunfile << "exec svlogd -tt #{logdir}"
      path_to_logrunfile = File.expand_path(File.join(@svlogdir, "run"))
      create_or_update_file(path_to_logrunfile, @logrunfile)
      File.chmod(0755, path_to_logrunfile) 
      path_to_logrunfile
    end
    
    # Makes the run script, which calls mongrel directly.  The command
    # line assembly code for mongrel_rails is taken verbatim from mongrel_cluster.
    def make_run
      cmd = if @config["command_line"]
        interpret_line(@config["command_line"])
      else
        argv = [ "mongrel_rails" ]
        argv << "start"
        argv << "-e #{@config["environment"]}" if @config["environment"]
        argv << "-p #{@config["port"]}"
        argv << "-a #{@config["address"]}"  if @config["address"]
        argv << "-l #{@config["log_file"]}" if @config["log_file"]
        argv << "-c #{File.expand_path(@config["cwd"])}" if @config["cwd"]
        argv << "-t #{@config["timeout"]}" if @config["timeout"]
        argv << "-m #{@config["mime_map"]}" if @config["mime_map"]
        argv << "-r #{@config["docroot"]}" if @config["docroot"]
        argv << "-n #{@config["num_procs"]}" if @config["num_procs"]
        argv << "-B" if @config["debug"]
        argv << "-S #{@config["config_script"]}" if @config["config_script"]
        argv << "--user #{@config["user"]}" if @config["user"]
        argv << "--group #{@config["group"]}" if @config["group"]
        argv << "--prefix #{@config["prefix"]}" if @config["prefix"]
        argv.join(" ")
      end
      env = nil
      if @config.has_key?("env_vars")
       env = "env"
       @config["env_vars"].each do |key, value|
         env << " #{key.upcase}=#{value}"
       end
      end
      @runfile = "#!/bin/sh\n"
      @runfile << "exec \\\n"
      @runfile << "  #{env} \\\n" if env
      @runfile << "  #{cmd} 2>&1\n"

      path_to_runfile = File.expand_path(File.join(@svdir, "run"))
      create_or_update_file(path_to_runfile, @runfile)
      File.chmod(0755, path_to_runfile)
      path_to_runfile
    end

    private
    
      def interpret_line(cmd)
        begin
          eval("\"#{cmd}\"")
        rescue SyntaxError
          puts "You have a syntax error in your string; perhaps you included a double quote without escaping it?"
          raise
        end        
      end
      
      def create_or_update_file(file, new_contents)
        write = 1
        if File.file?(file)
          current_contents = IO.read(file)
          if current_contents == new_contents
            write = nil
          end
        end
        
        File.open(file, "w") do |file|
          file.print(new_contents)
        end if write
      end
  end
end