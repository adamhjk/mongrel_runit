#!/usr/bin/env ruby
#
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


module MongrelRunit
  
  # A simple base class, that defines a list of allowed commands.  
  class Base
    ALLOWEDCOMMANDS = [
      "up",
      "down",
      "status",
      "once",
      "pause",
      "cont",
      "hup",
      "alarm",
      "interrupt",
      "1",
      "2",
      "term",
      "kill",
      "exit",
      "start",
      "stop",
      "restart",
      "shut-down",
      "force-stop",
      "force-reload",
      "force-restart",
      "force-shutdown",
    ]
    
    # Returns a given command if it's found in the allowed commands
    # list.  
    def has_command?(command)
      ALLOWEDCOMMANDS.detect { |cmd| cmd == command }
    end
    
  end
end