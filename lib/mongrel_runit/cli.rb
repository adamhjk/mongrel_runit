#!/usr/bin/env ruby
#
# Author:: Adam Jacob (<adam@hjksolutions.com>)
# Copyright:: Copyright (c) 2007 HJK Solutions, LLC
# License:: GNU General Public License version 2
#
#--
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
#++

require 'optparse'
require 'mongrel_runit/servicerunner'
require 'mongrel_runit/config'
require 'yaml'

module MongrelRunit
  
# The command line interface. 
#
# Example:
# 
#   cli = MongrelRunit::CLI.new(ARGV)
#   cli.execute
#

  class CLI

    # Takes a list of command line arguments, passing them to 
    # MongrelRunit::Config and MongrelRunit::ServiceRunner.
    def initialize(args)
      @config = MongrelRunit::Config.load_args(args)
      @servicerunner = MongrelRunit::ServiceRunner.new(@config.config)
    end
    
    # Executes the command (start/stop/restart; see MongrelRunit::Base for the 
    # list) specified by the arguments passed to MongrelRunit::CLI.  The
    # command is executed by calling MongrelRunit::ServiceRunner.run.
    def execute
      response, status = @servicerunner.run(@config.command)
      if @config.verbose || status == false
        response.sort.each do |key, value|
          puts "#{key}: #{value[1]}: #{value[0]}"
        end
      end
      exit 1 if status == false
      exit 0 if status == true
    end
  end
end