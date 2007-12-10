README for mongrel_runit
========================

This is a mongrel_cluster replacement using runit to control a set of mongrel
instances.  It provides all of the features inherent in services being
managed by runit, and knows how to check each running mongrel for status.

Debt of Gratitude
=================

Mongrel Runit was greatly inspired by mongrel_cluster, and some portions
of it are taken verbatim: particularly the code to construct a mongrel's
command line arguments.  

Requirements
============

1. Mongrel (gem install mongrel)
2. runit (http://smarden.org/runit/)

You will need to have runit installed, and the permissions on /etc/sv and
/var/service (or equivalents) be correct. (You will need to allow the
user running 'mongrel_runit create' to create the right directories)

Usage
=====

You will need to have the proper service directories created in order to
have them managed by mongrel_runit.  We handle that for you through:

    mongrel_runit create
    
This will read the configuration and create the proper number of mongrel
services.  If you change the configuration, either to alter the number
of running mongrels or anything else, simply run mongrel_runit create
again.  It knows what "should" be there, and will clean up after you.

Once that is done, you should be able to do:

    mongrel_runit stop|start|restart
    
For a full list of options, run mongrel_runit -h

Configuration
=============

We look for the configuration file in a number of different places.  With
no arguments at all, we assume that we are in a Rails applications base
directory already, with a:

    ./config/mongrel_runit.yml
    
            or
    
    ./config/mongrel_cluster.yml
    
File.  If we find one, we will load it and go to town.  If you are 
reusing a mongrel_cluster.yml file, you will likely need to specify
the "-a appname" argument.

YAML file options are identical to mongrel_cluster, and represent
options to mongrel_rails:

environment
port
address
log_file
cwd
timeout
mime_map
docroot
debug
config_script
user
group
prefix

Additional, mongrel_runit specific options are:

application_name: This is the "name" of your rails app. We use it to construct
    the actual name of the service directory.  So "foo" becomes 
    "mongrel-foo-port"

runit_sv_dir: Where to create the service directories.  Defaults to /etc/sv

runit_service_dir: Where to create the symlinks for runsvdir to pick up.
    Defaults to /var/service

check: A block of code that will become the check file.  By default, it is:

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

    This will be created for each service, and used to report the final
    status when running "mongrel_runit start"

svlogd_config: Another code block, which sets up the log configuration.
    See the svlogd manpage for options.
    
base_log_directory: By default, your logs will wind up under each service
    directory in "log/main/current".  You can override this directory
    here.  If you do, each log will wind up in a subdirectory named after
    the service.  For example, setting base_log_directory to "/tmp" would
    create:
    
        /tmp/mongrel-appname-port/current
    
    For your logs.  Not a bad idea to set this to your applications "log"
    directory.
    