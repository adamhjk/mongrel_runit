require File.dirname(__FILE__) + '/test_helper.rb'

require "mongrel_runit/config"
require "yaml"

class TestMongrelRunitConfig < Test::Unit::TestCase
  YAMLFILE = File.dirname(__FILE__) + "/config/mongrel_runit.yml"
  ARGS = " -e PRODUCTION"
  ARGS << " -p 8000"
  ARGS << " -a 127.0.0.1"
  ARGS << " -l log/file.log"
  ARGS << " -P log/file.pid" 
  ARGS << " -n 1024"
  ARGS << " -m mime-types.conf"
  ARGS << " -c /tmp"
  ARGS << " -r /tmp"
  ARGS << " --debug"
  ARGS << " -C /conf/path"
  ARGS << " -S /conf/path/script"
  ARGS << " --user www-data" 
  ARGS << " --group www-data"
  
  def setup
    @file_template = {
      :port => 3000,
      :address => '127.0.0.1',
      :pid_file => 'log/mongrel.pid',
      :servers => 2,
      :log_file => 'foo.log',
      :environment => "production",
      :cwd => "/Users/adam/src/sandbox/mongrel_runit",
      :timeout => 100,
      :mime_map => "log/mime.map",
      :docroot => "htdocs",
      :num_procs => 1024,
      :debug => true,
      :config_path => "/foo/bar/config",
      :config_script => "/foo/bar/config/yml",
      :user => "www-data",
      :group => "www-data",
      :prefix => "/monkey",
      :runit_sv_dir => "/etc/sv",
      :runit_service_dir => "/var/service",
      :application_name => "monkey",
    }
  end
  
  def load_file
    @from_file = MongrelRunit::Config.load_file(YAMLFILE)
  end
  
  def load_args(args)
     config = MongrelRunit::Config.load_args(args)
  end
  
  def test_load_args
    args = [ "-c#{File.expand_path('./config/mongrel_runit.yml')}", "status" ]
    config = load_args(args)
    @file_template.each do |key, value|
      assert_equal(value, config["#{key}"], "#{key} has proper value")
    end
  end
  
  def test_load_appname_args
    args = [ 
      "-c#{File.expand_path('./config/mongrel_runit.yml')}",
      "-amoo",
      "status", 
      ]
    config = load_args(args)
    @file_template[:application_name] = "moo"
    @file_template.each do |key, value|
      assert_equal(value, config["#{key}"], "#{key} has proper value")
    end
    assert_equal("status", config.command, "Command is correct")
  end
  
  def test_load_nothing
    args = [ "status" ]
    config = load_args(args)
    @file_template.each do |key, value|
      assert_equal(value, config["#{key}"], "#{key} has proper value")
    end
    assert_equal("status", config.command, "Command is correct")
  end
  
  def test_load_file
    load_file
    @file_template.each do |key, value|
      assert_equal(value, @from_file["#{key}"], "#{key} has proper value")
    end
  end
end