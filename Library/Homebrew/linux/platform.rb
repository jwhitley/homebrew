#require 'linux/hardware'

module Platform

  class << self
    def setup
    end
    
    def cache
      if Process.uid == 0
        # technically this is not the correct place, this cache is for *all users*
        # so in that case, maybe we should always use it, root or not?
        Pathname.new("/Library/Caches/Homebrew")
      else
        Pathname.new("~/Library/Caches/Homebrew").expand_path
      end
    end
    
    def dump
      # Platform information dump
      ""
    end

    def identifier
      `uname -a`
    end

    def install_check
      unless File.exist?('/usr/bin/gcc')
        # the reason we don't abort is some formula don't require gcc
        # TODO allow formula to declare themselves as "not needing gcc"
        opoo "Xcode is not installed! Builds may fail!"
      end
    end

    def setup_build_environment
      @@cflags = ['-O3']
    end

    def cflags
      # optimise all the way to eleven, references:
      # http://en.gentoo-wiki.com/wiki/Safe_Cflags/Intel
      # http://forums.mozillazine.org/viewtopic.php?f=12&t=577299
      # http://gcc.gnu.org/onlinedocs/gcc-4.2.1/gcc/i386-and-x86_002d64-Options.html
=begin
      if MACOS_VERSION >= 10.6
        case Hardware.intel_family
        when :penryn, :core2
          # no need to add -mfpmath it happens automatically with 64 bit compiles
          @@cflags << "-march=core2"
        when :core
          @@cflags<<"-march=prescott"<<"-mfpmath=sse"
        end
      else
        case Hardware.intel_family
        when :penryn, :core2
          @@cflags<<"-march=nocona"
        when :core
          @@cflags<<"-march=prescott"
        end
        @@cflags<<"-mfpmath=sse"
      end
      @@cflags<<"-mmmx"
      case Hardware.intel_family
      when :nehalem
        @@cflags<<"-msse4.2"
      when :penryn
        @@cflags<<"-msse4.1"
      when :core2, :core
        @@cflags<<"-msse3"
      end
=end
      @@cflags
    end

    protected
    def x11_installed?
      Pathname.new('/usr/lib/libX11.so').exist?
    end
  end # << self

  module EnvExtension
    def x11
      opoo "You do not have X11 installed, this formula may not build." if not x11_installed?
      
      # CPPFLAGS are the C-PreProcessor flags, *not* C++!
      append 'CPPFLAGS', '-I/usr/include'
      append 'LDFLAGS', '-L/usr/lib'
    end
    alias_method :libpng, :x11

  end # module EnvExtension

end # module Platform
