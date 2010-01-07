#  Copyright 2009 John Whitley.
#
#  Redistribution and use in source and binary forms, with or without
#  modification, are permitted provided that the following conditions
#  are met:
#
#  1. Redistributions of source code must retain the above copyright
#     notice, this list of conditions and the following disclaimer.
#  2. Redistributions in binary form must reproduce the above copyright
#     notice, this list of conditions and the following disclaimer in the
#     documentation and/or other materials provided with the distribution.
#
#  THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
#  IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
#  OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
#  IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
#  INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
#  NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
#  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
#  THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
#  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
#  THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# Platform/OS abstraction layer for Homebrew

module PlatformFactory
  def self.type
    @@type
  end

  def self.platform
    @@platform
  end

  def self.setup
    unless defined? @@type
      uname_platform = `uname`
      case `uname`
      when /Darwin/
        @@type = :macosx
        require 'macosx/platform'
        require 'macosx/hardware'
        require 'macosx/beer_events'
      when /Linux/
        @@type = :linux
        abort 'Linux is not yet supported.'
      when /CYGWIN_NT\*/
        @@type = :cygwin
        abort 'Cygwin is not yet supported.'
      when /SunOS/
        @@type = :solaris
        abort 'Solaris is not yet supported.'
      end
    end
    ::Platform = @@platform
    ::Hardware = @@hardware
  end

  class Base
    REQUIRED_METHODS = %(identifier install_check setup_build_environment)

    REQUIRED_METHODS.each |m|
      class_eval(<<-EOS, __FILE__, __LINE__+1)
        def #{m}
          raise NotImplementedError, "Required method '#{m}' not implemented by #{self.class}"
        end
      EOS
    end
  end
end
