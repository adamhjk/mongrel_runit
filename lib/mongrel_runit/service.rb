#  Created by Adam Jacob on 2007-03-21.
#  Copyright (c) 2007. All rights reserved.

require 'mongrel_runit/base'

module MongrelRunit
  class Service < Base
    
    attr_reader :runfile, :logrunfile, :logconfig, :checkfile, :config, :svdir
    
    def initialize(config)
      @config = config
      
      raise ArgumentError, "Must have an application_name!" unless @config.has_key?("application_name")
      raise ArgumentError, "Must have a port!" unless @config.has_key?("port")
      raise ArgumentError, "Must have a runit_sv_dir!" unless @config.has_key?("runit_sv_dir")
      raise ArgumentError, "Must have a runit_service_dir!" unless @config.has_key?("runit_service_dir")
      
      check_service_dir
      make_sv_dir 
    end
    
    def method_missing(status)
      if self.has_command?(status.id2name)
        run(status.id2name)
      else
        Kernel.method_missing
      end
    end
    
    def is_running? 
      output, success = run("status")
      output =~ /^run:/ ? true : nil
    end
    
    def run(status)
      cmd = "sv #{status} #{@svdir}"
      output = `#{cmd}`
      return output, $?.success?
    end
    
    def create
      make_run
      make_check
      make_log
      make_log_config
      link = make_service_link
      return link, true
    end
    
    def check_service_dir
      dir_exists = File.directory?(@config["runit_service_dir"])
      raise ArgumentError, "runit_service_dir does not exist: #{@config["runit_service_dir"]}" unless dir_exists
      dir_exists
    end
    
    def make_service_link
      servicename = File.basename(@svdir)
      link = File.expand_path(File.join(@config["runit_service_dir"], servicename))
      unless File.symlink?(link)
        `ln -s #{@svdir} #{@config["runit_service_dir"]}`
      end
      link
    end
    
    def make_check
      address = @config["address"] || '127.0.0.1'
      @checkfile = @config["checkfile"] || <<EOH
#!/usr/bin/env ruby

require 'net/http'

http = Net::HTTP.new('#{address}', #{@config["port"].to_i})
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
      path_to_checkfile = File.expand_path(File.join(@svdir, "check"))
      create_or_update_file(path_to_checkfile, @checkfile)
      File.chmod(0755, path_to_checkfile)
      path_to_checkfile
    end
    
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
    
    def make_log_config
      path_to_file = nil
      if @config.has_key?("svlogd_config")
        path_to_file = File.expand_path(File.join(@svlogdir, "config"))
        @logconfig = @config["svlogd_config"]
        create_or_update_file(path_to_file, @logconfig)
      end
      path_to_file
    end
    
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
    
    def make_run
      # Taken from mongrel_cluster pretty much verbatim
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
       cmd = argv.join " "
       
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