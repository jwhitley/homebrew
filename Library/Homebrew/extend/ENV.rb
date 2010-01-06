#  Copyright 2009 Max Howell and other contributors.
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
#

module HomebrewEnvExtension
  # -w: keep signal to noise high
  SAFE_CFLAGS_FLAGS = "-w -pipe"

  def setup_build_environment
    # Clear CDPATH to avoid make issues that depend on changing directories
    ENV.delete('CDPATH')
    ENV.delete('CPPFLAGS')
    ENV.delete('LDFLAGS')
    ENV.delete('CC')
    ENV.delete('CXX')

    ENV['MAKEFLAGS']="-j#{Hardware.processor_count}"

    unless HOMEBREW_PREFIX.to_s == '/usr/local'
      # /usr/local is already an -isystem and -L directory so we skip it
      ENV['CPPFLAGS'] = "-isystem #{HOMEBREW_PREFIX}/include"
      ENV['LDFLAGS'] = "-L#{HOMEBREW_PREFIX}/lib"
      # CMake ignores the variables above
      ENV['CMAKE_PREFIX_PATH'] = "#{HOMEBREW_PREFIX}"
    end

    # Defer any truly platform-specific environment building to the
    # platform driver
    Platform.setup_build_environment
  end
  
  def deparallelize
    remove 'MAKEFLAGS', /-j\d+/
  end
  alias_method :j1, :deparallelize

  # recommended by Apple, but, eg. wget won't compile with this flag, so…
  def fast
    remove_from_cflags /-O./
    append_to_cflags '-fast'
  end
  def O3
    # Sometimes O4 just takes fucking forever
    remove_from_cflags /-O./
    append_to_cflags '-O3'
  end
  def O2
    # Sometimes O3 doesn't work or produces bad binaries
    remove_from_cflags /-O./
    append_to_cflags '-O2'
  end
  def Os
    # Sometimes you just want a small one
    remove_from_cflags /-O./
    append_to_cflags '-Os'
  end

  def minimal_optimization
    self['CFLAGS']=self['CXXFLAGS']="-Os #{SAFE_CFLAGS_FLAGS}"
  end
  def no_optimization
    self['CFLAGS']=self['CXXFLAGS'] = SAFE_CFLAGS_FLAGS
  end

  def libxml2
    append_to_cflags ' -I/usr/include/libxml2'
  end

  # we've seen some packages fail to build when warnings are disabled!
  def enable_warnings
    remove_from_cflags '-w'
  end
  # Snow Leopard defines an NCURSES value the opposite of most distros
  # See: http://bugs.python.org/issue6848
  def ncurses_define
    append 'CPPFLAGS', "-DNCURSES_OPAQUE=0"
  end
  # returns the compiler we're using
  def cc
    ENV['CC'] or "gcc"
  end
  def cxx
    ENV['CXX'] or "g++"
  end

  def m64
    append_to_cflags '-m64'
    ENV.append 'LDFLAGS', '-arch x86_64'
  end
  def m32
    append_to_cflags '-m32'
    ENV.append 'LDFLAGS', '-arch i386'
  end

  def prepend key, value, separator = ' '
    unless self[key].to_s.empty?
      self[key] = value + separator + self[key]
    else
      self[key] = value
    end
  end
  def append key, value, separator = ' '
    ref=self[key]
    if ref.nil? or ref.empty?
      self[key]=value
    else
      self[key]=ref + separator + value
    end
  end
  def append_to_cflags f
    append 'CFLAGS', f
    append 'CXXFLAGS', f
  end
  def remove key, value
    return if self[key].nil?
    self[key]=self[key].sub value, '' # can't use sub! on ENV
    self[key]=nil if self[key].empty? # keep things clean
  end
  def remove_from_cflags f
    remove 'CFLAGS', f
    remove 'CXXFLAGS', f
  end
end
