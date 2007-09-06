# Author:: Adam Jacob (<adam@hjksolutions.com>)
# Copyright:: Copyright (c) 2007 HJK Solutions, LLC
# License:: GNU General Public License version 2
#---
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 
# as published by the Free Software Foundation.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#+++

require 'yaml'
require 'optparse'
require 'mongrel_runit/base'

module MongrelRunit
  
  # Takes a YAML config file and a list of command line arguments, and
  # populates itself with the resulting combined configuration. 
  #
  # Example:
  #
  #   config = MongrelRunit::Config('monkey', '/etc/sv/monkey.yml', ARGV)
  #   puts config["application_name"] # monkey
  #  
  class Config < Base
    attr_accessor :config, :command, :verbose
    
    # Takes an application name, a YAML file, and command line arguments
    # and spits out a working configuration.  The YAML file and arguments
    # can optionally be nil.
    #
    # Unless otherwise specified, the following default values are
    # set:
    #
    #    environment: ENV["RAILS_ENV"] or development
    #    port: 3000
    #    servers: 2
    #    runit_svdir: /etc/sv
    #    runit_service_dir: /var/service
    def initialize(appname, yamlfile, args)
      @config = Hash.new
      load_args(args) if args
      load_yaml(yamlfile) if yamlfile
      @config["environment"] ||= ENV["RAILS_ENV"] || 'development'
      @config["port"] ||=  "3000"
      @config["servers"] ||= 2
      @config["application_name"] ||= appname
      @config["runit_svdir"] ||= '/etc/sv'
      @config["runit_service_dir"] ||= '/var/service'
      
      raise ArgumentError, "Must supply an application_name!" unless @config["application_name"]
      
    end
    
    # Returns the value from the config hash.
    def [](arg)
      @config[arg]
    end
    
    # Load options from a config file alone
    def Config.load_file(yamlfile)
      MongrelRunit::Config.new(nil, yamlfile, nil)
    end
    
    # Load options from command line arguments alone
    def Config.load_args(*args)
     MongrelRunit::Config.new(nil, nil, *args)
    end
    
    private
    
      def load_yaml(yamlfile)
        @config = YAML.load_file(File.expand_path(yamlfile))
      end
      
      def load_from_path(path)
        path.strip!
        epath = File.expand_path(path)
        @path = epath
        mr_conf = File.expand_path(File.join(epath, "config", "mongrel_runit.yml"))
        mc_conf = File.expand_path(File.join(epath, "config", "mongrel_cluster.yml"))
        if File.file?(mr_conf)
          load_yaml(mr_conf)
        elsif File.file?(mc_conf)
          load_yaml(mc_conf)
        else
          puts "#{path} must have a ./config/mongrel_runit.yml or ./config/mongrel_cluster.yml"
          return nil
        end
        return true
      end
      
      def load_args(args)
        
        loaded_config = nil
        
        opts = OptionParser.new do |opts|
          opts.banner = "Usage: #{$0} (options) (#{ALLOWEDCOMMANDS.join('|')})"
                    
          opts.on("-p PATH", "--path PATH", "Path to a Rails app to start") do |p|
            loaded_config = load_from_path(p)
          end
          
          opts.on("-a NAME", "--application NAME", "The name of your Application. (Used for the service directories)") do |a|
            @config["application_name"] = a
          end
          
          opts.on("-c FILE", "--config FILE", "A mongrel_runit.yml config file") do |c|
            c.strip!
            file = File.expand_path(c)
            if File.file?(file)
              load_yaml(file)
              loaded_config = true
            else
              puts "I could not find config file: #{file}"
              exit 1
            end
          end
              
          opts.on_tail("-v", "--verbose", "Be verbose") do
            @verbose = true
          end
          
          opts.on_tail("-h", "--help", "Show this message") do
            puts opts
            exit
          end
        end
        opts.parse!(args)
        
        unless loaded_config
          path = Dir.getwd
          loaded_config = load_from_path(path)
        end
           
        if loaded_config && ! @config["application_name"]
          if @path
            appname = File.basename(@path)      
            @config["application_name"] = appname
          else
            puts "You need application_name defined in your config!"
            YAML.dump @config
            exit 1
          end
        end
        
        unless loaded_config
          puts "Configuration Dump:\n\n"
          puts YAML.dump(@config)
          puts "I could not find a way to configure myself properly!\n"
          puts opts.help
          exit 1
        end
     
        if args.length > 1
          puts "You specified more command line arguments than I can handle:"
          puts args.join(" ")
          puts opts.help
          exit 1
        end
      
        if self.has_command?(args[0]) || args[0] == "create"
          @command = args[0]
        else
          if args[0]
            puts "#{args[0]} is not an allowed command"
          else 
            puts "You must provide a command!"
          end
          puts opts.help
          exit 1
        end 
      end
  end
end