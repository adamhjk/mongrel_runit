require 'mongrel_runit/base'
require 'mongrel_runit/service'
require 'find'

module MongrelRunit
  class ServiceRunner < Base
    include Enumerable 
    
    def initialize(config)
      @config = config
      @mongrel_services = {}
      @mongrel_names = []
      
      raise ArgumentError, "Must have an application_name!" unless @config.has_key?("application_name")
      raise ArgumentError, "Must have a port!" unless @config.has_key?("port")
      raise ArgumentError, "Must have a servers option!" unless @config.has_key?("servers")
      
      start_port = @config["port"].to_i
      port_end = start_port + @config["servers"].to_i - 1
      start_port.upto(port_end) do |port|
        local_config = config.dup
        local_config["port"] = port
        @mongrel_services[port] = MongrelRunit::Service.new(local_config)
        @mongrel_names << "mongrel-#{@config["application_name"]}-#{port}"
      end
    end
    
    def method_missing(method)
      if self.has_command?(method.id2name) || method.id2name == "create"
        run(method.id2name)
      else
        super
      end
    end
    
    def run(method)
      return self.create if method == "create"
      threads = []
      response = {}
      final_status = true
      self.each do |svc|
        threads << Thread.new(svc) do |s|
          output, status = s.send(:run, method)
          response[svc.config["port"]] = [ output, status ]
          final_status = status if status == false
        end
      end
      threads.each { |t| t.join }
      return response, final_status
    end
    
    def create
  
      response = {}
      final_status = true
      self.each do |svc|
        output, status = svc.create
        response[svc.config["port"]] = [ output, status ]
        final_status = status if status == false
      end
      
      service_path = File.expand_path(@config["runit_service_dir"])
      sv_path = File.expand_path(@config["runit_sv_dir"])
      Find.find(sv_path, service_path) do |file|
        if File.directory?(file) || File.symlink?(file)
          if file =~ /mongrel-#{@config["application_name"]}-(\d+)$/
            safe = @mongrel_names.detect { |cm| cm =~ /#{File.basename(file)}$/ }
            if ! safe
              output = `rm -r #{file}`
              raise "Cannot remove stale mongrel config" unless $?.success?
            end
          end
        end
      end
      return response, final_status
    end
    
    def [](port)
      @mongrel_services[port]
    end
    
    def length
      @mongrel_services.length
    end
    
    def each
      @mongrel_services.each_value { |value| yield value }
    end
    
  end
end