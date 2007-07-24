require File.dirname(__FILE__) + '/test_helper.rb'

require "mongrel_runit/servicerunner"
require "find"

class TestMongrelRunitServiceRunner < Test::Unit::TestCase
  
  def setup
    @config = {
     "port" => "8191",
     "address" => "127.0.0.1",
     "servers" => "2",
     "environment" => "production",
     "cwd" => File.dirname(__FILE__) + '/testapp',
     "num_procs" => "1024",
     #"user" => "www-data",
     #"group" => "www-data",
     "runit_sv_dir" => File.dirname(__FILE__) + "/sv",
     "runit_service_dir" => File.dirname(__FILE__) + "/service",
     "application_name" => "monkey",
     "svlogd_config" => <<EOH
s100000
n100
EOH
    }
    @servicerunner = MongrelRunit::ServiceRunner.new(@config)
  end
  
  def teardown
    cleanup
  end
  
  def test_service_create
    assert_equal(MongrelRunit::ServiceRunner, @servicerunner.class, "Got the right object")
  end

  def test_create
    result, status = @servicerunner.create
    @servicerunner.each do |service|
      assert(result.has_key?(service.config["port"]), "Created #{service.config['port']}")
      assert(File.directory?(service.svdir), "Created svdir")
    end 
  end
  
  def test_run_start
    if ENV["RUNSVTEST"]
      result, status = @servicerunner.create
      assert(status, "Created for each service")
      sleep 5
      result, status = @servicerunner.start
      assert(status, "Started each service")
    end
  end
  
  def test_run_stop
    if ENV["RUNSVTEST"]
      result, status = @servicerunner.create
      assert(status, "Created each service")
      sleep 5
      result, status = @servicerunner.stop
      assert(status, "Stopped each service")
    end
  end
  
  def cleanup
    Find.find(@config["runit_sv_dir"], @config["runit_service_dir"]) do |file|
      if File.directory?(file) || File.symlink?(file)
        if File.basename(file) =~ /mongrel-(.+)-(\d+)/
         `rm -r #{file}`
        end
      end
    end
  end
end