require File.dirname(__FILE__) + '/test_helper.rb'

require "mongrel_runit/config"
require "mongrel_runit/service"
require "find"

class TestMongrelRunitService < Test::Unit::TestCase
  
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
    @service = MongrelRunit::Service.new(@config)
  end
  
  def teardown
    cleanup
  end
  
  def test_service_create
    assert_equal(MongrelRunit::Service, @service.class, "Got the right object")
  end
  
  def test_run_testapp
    @service.create
    if ENV["RUNSVTEST"]
      sleep 5
      output, status = @service.start
      assert(status, "Service Start")
      ouput, status = @service.stop
      assert(status, "Service Stop")
      output, status = @service.start
      assert(status, "Service Start")
    end
  end
  
  def test_make_service_link
    @service.create
    link = @service.make_service_link
    assert(File.symlink?(link), "Created service symlink")
  end
  
  def test_make_sv_dir
    svlogdir = @service.make_sv_dir
    assert(File.directory?(svlogdir), "Created sv directory")
  end
  
  def test_check_service_dir
    dir_exists = @service.check_service_dir
    assert(dir_exists, "Has a service directory")
  end
  
  def test_make_log
    runlog = @service.make_log
    assert_equal(@service.logrunfile, IO.read(runlog), "log/run file created")
    assert(File.executable?(runlog), "log/run file executable")
  end
   
  def test_make_check
    checkfile = @service.make_check
    assert_equal(@service.checkfile, IO.read(checkfile), "check file created")
    assert(File.executable?(checkfile), "check file executable")
  end
  
  def test_make_log_config
    logconfig = @service.make_log_config
    assert_equal(@service.logconfig, IO.read(logconfig)) if logconfig
  end
  
  def test_make_run    
    no_env_runfile = @service.make_run
    no_env_file = <<EOH
#!/bin/sh
exec \\
  mongrel_rails start -e production -p 8191 -a 127.0.0.1 -c #{File.dirname(__FILE__) + '/testapp'} -n 1024 2>&1
EOH
    env_file = <<EOH
#!/bin/sh
exec \\
  env PATH=$PATH:/var/lib/gems/1.8 \\
  mongrel_rails start -e production -p 8191 -a 127.0.0.1 -c #{File.dirname(__FILE__) + '/testapp'} -n 1024 2>&1
EOH
    command_line_file = <<EOH
#!/bin/sh
exec \\
  moofyboogles -p 8191 2>&1
EOH
    assert_equal(no_env_file, @service.runfile)
    assert_equal(@service.runfile, IO.read(no_env_runfile))
    
    env_config = @config.dup
    env_config["env_vars"] = { "PATH" => "$PATH:/var/lib/gems/1.8" }
    env_service = MongrelRunit::Service.new(env_config)
    env_service_runfile = env_service.make_run
    assert_equal(env_file, env_service.runfile)
    assert_equal(env_service.runfile, IO.read(env_service_runfile))
    assert(File.executable?(env_service_runfile), "run file executable")
    
    command_line_config = @config.dup
    command_line_config["command_line"] = 'moofyboogles -p #{@config["port"]}'
    command_line_service = MongrelRunit::Service.new(command_line_config)
    command_line_runfile = command_line_service.make_run
    assert_equal(command_line_file, command_line_service.runfile, "Command line runfile works")
    assert_equal(command_line_service.runfile, IO.read(command_line_runfile), "Command line generated file works")
  end
  
  def cleanup
   Find.find(@config["runit_sv_dir"], @config["runit_service_dir"]) do |file|
     if File.directory?(file) || File.symlink?(file)
       if File.basename(file) =~ /(.+)-(\d+)/
         `rm -r #{file}`
       end
     end
   end
  end
end

