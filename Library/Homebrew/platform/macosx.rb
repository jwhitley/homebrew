require 'platform'
require 'platform/macosx_hardware'

class Platform::MacOSX < Platform::Base

  module EnvExtension
    def gcc_4_0_1
      self['CC'] = self['LD'] = '/usr/bin/gcc-4.0'
      self['CXX'] = '/usr/bin/g++-4.0'
      self.O3
      remove_from_cflags '-march=core2'
      remove_from_cflags %r{-msse4(\.\d)?/}
    end
    alias_method :gcc_4_0, :gcc_4_0_1
    
    def gcc_4_2
      # Sometimes you want to downgrade from LLVM to GCC 4.2
      self['CC']="/usr/bin/gcc-4.2"
      self['CXX']="/usr/bin/g++-4.2"
      self['LD']=self['CC']
      self.O3
    end
    
    def osx_10_4
      self['MACOSX_DEPLOYMENT_TARGET']="10.4"
      remove_from_cflags(/ ?-mmacosx-version-min=10\.\d/)
      append_to_cflags('-mmacosx-version-min=10.4')
    end
    def osx_10_5
      self['MACOSX_DEPLOYMENT_TARGET']="10.5"
      remove_from_cflags(/ ?-mmacosx-version-min=10\.\d/)
      append_to_cflags('-mmacosx-version-min=10.5')
    end

    # i386 and x86_64 only, no PPC
    def universal_binary
      append_to_cflags '-arch i386 -arch x86_64'
      ENV.O3 if self['CFLAGS'].include? '-O4' # O4 seems to cause the build to fail
      ENV.append 'LDFLAGS', '-arch i386 -arch x86_64'
    end

    def x11
      opoo "You do not have X11 installed, this formula may not build." if not x11_installed?
    
      # CPPFLAGS are the C-PreProcessor flags, *not* C++!
      append 'CPPFLAGS', '-I/usr/X11R6/include'
      append 'LDFLAGS', '-L/usr/X11R6/lib'
      # CMake ignores the variables above
      append 'CMAKE_PREFIX_PATH', '/usr/X11R6', ':'
    end
    alias_method :libpng, :x11

  end # module EnvExtension

  def cache
    if Process.uid == 0
      # technically this is not the correct place, this cache is for *all users*
      # so in that case, maybe we should always use it, root or not?
      Pathname.new("/Library/Caches/Homebrew")
    else
      Pathname.new("~/Library/Caches/Homebrew").expand_path
    end
  end

  def initialize
    @full_version = `/usr/bin/sw_vers -productVersion`.chomp
    @version = /(10\.\d+)(\.\d+)?/.match(@full_version).captures.first.to_f

    if @version < 10.5
      abort "Homebrew requires Leopard or higher, but you could fork it and fix that..."
    end
    
  end

  def dump
    llvm = llvm_build
    gcc = gcc_build
    <<-EOS
GCC-4.2: #{gcc ? "build #{gcc}" : "N/A"} (5577 or newer recommended)
LLVM: #{llvm ? "build #{llvm}" : "N/A" } #{llvm ? "(2206 or newer recommended)" : "" }
MacPorts or Fink? #{macports_or_fink_installed?}
X11 installed? #{x11_installed?}
    EOS
  end

  def identifier
    "Mac OS X #{@full_version}"
  end

  def install_check
    begin
      if MACOS_VERSION >= 10.6
        opoo "You should upgrade to Xcode 3.2.1" if llvm_build < 2206
      else
        opoo "You should upgrade to Xcode 3.1.4" if gcc_build < 5577
      end
    rescue
      # the reason we don't abort is some formula don't require Xcode
      # TODO allow formula to declare themselves as "not needing Xcode"
      opoo "Xcode is not installed! Builds may fail!"
    end

    if macports_or_fink_installed?
      opoo "It appears you have Macports or Fink installed"
      puts "Although, unlikely, this can break builds or cause obscure runtime issues."
      puts "If you experience problems try uninstalling these tools."
    end
  end

  def setup_build_environment
    if MACOS_VERSION >= 10.6 or ENV['HOMEBREW_USE_LLVM']
      # you can install Xcode wherever you like you know.
      prefix = `/usr/bin/xcode-select -print-path`.chomp
      prefix = "/Developer" if prefix.to_s.empty?
      
      ENV['CC'] = "#{prefix}/usr/bin/llvm-gcc"
      ENV['CXX'] = "#{prefix}/usr/bin/llvm-g++"
      cflags = %w{-O4} # link time optimisation baby!
    else
      cflags = ['-O3']
    end
    # in rare cases this may break your builds, as the tool for some reason wants
    # to use a specific linker, however doing this in general causes formula to
    # build more successfully because we are changing CC and many build systems
    # don't react properly to that
    ENV['LD'] = ENV['CC'] if ENV['CC']

    # optimise all the way to eleven, references:
    # http://en.gentoo-wiki.com/wiki/Safe_Cflags/Intel
    # http://forums.mozillazine.org/viewtopic.php?f=12&t=577299
    # http://gcc.gnu.org/onlinedocs/gcc-4.2.1/gcc/i386-and-x86_002d64-Options.html
    # we don't set, eg. -msse3 because the march flag does that for us
    #   http://gcc.gnu.org/onlinedocs/gcc-4.3.3/gcc/i386-and-x86_002d64-Options.html
    if MACOS_VERSION >= 10.6
      case Hardware.intel_family
      when :nehalem, :penryn, :core2
        # the 64 bit compiler adds -mfpmath=sse for us
        cflags << "-march=core2"
      when :core
        cflags<<"-march=prescott"<<"-mfpmath=sse"
      end
      # gcc doesn't auto add msse4 or above (based on march flag) yet
      case Hardware.intel_family
      when :nehalem
        cflags << "-msse4" # means msse4.2 and msse4.1
      when :penryn
        cflags << "-msse4.1"
      end
    else
      # gcc 4.0 didn't support msse4
      case Hardware.intel_family
      when :nehalem, :penryn, :core2
        cflags<<"-march=nocona"
      when :core
        cflags<<"-march=prescott"
      end
      cflags<<"-mfpmath=sse"
    end
    
    ENV['CFLAGS'] = ENV['CXXFLAGS'] = "#{cflags*' '} #{SAFE_CFLAGS_FLAGS}"
  end

  protected
  def llvm_build
    if MACOS_VERSION >= 10.6
      `/Developer/usr/bin/llvm-gcc-4.2 -v 2>&1` =~ /LLVM build (\d{4,})/  
      $1.to_i
    end
  end

  def gcc_build
    `/usr/bin/gcc-4.2 -v 2>&1` =~ /build (\d{4,})/
    if $1
      $1.to_i 
    elsif system "/usr/bin/which gcc"
      # Xcode 3.0 didn't come with gcc-4.2
      # We can't change the above regex to use gcc because the version numbers
      # are different and thus, not useful.
      # FIXME I bet you 20 quid this causes a side effect — magic values tend to
      401
    else
      nil
    end
  end

  def x11_installed?
    Pathname.new('/usr/X11/lib/libpng.dylib').exist?
  end

end # class
