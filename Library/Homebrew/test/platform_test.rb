#!/usr/bin/ruby
# This software is in the public domain, furnished "as is", without technical
# support, and with no warranty, express or implied, as to its usefulness for
# any purpose.

$:.push(File.expand_path(__FILE__+'/../..'))
require 'test/unit'

class 

  REQUIRED_METHODS = %(identifier install_check setup_build_environment)
  def self.verify_platform
    
  end

  class Base

    REQUIRED_METHODS.each |m|
      class_eval(<<-EOS, __FILE__, __LINE__+1)
        def #{m}
          raise NotImplementedError, "Required method '#{m}' not implemented by #{self.class}"
        end
      EOS
    end
  end
