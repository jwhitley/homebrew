# empty
module Hardware

  def self.cpu_type
    @@cpu_type ||= `arch`
    case @@cpu_type
    when /i386|x86_64/
      :intel
    else
      :dunno
    end
  end

  def self.processor_count
    @@processor_count ||= `cat /proc/cpuinfo | grep '^processor[ \t]*:' | wc -l`.to_i
  end

  def self.cores_as_words
    case Hardware.processor_count
    when 1 then 'single'
    when 2 then 'dual'
    when 4 then 'quad'
    else
      Hardware.processor_count
    end
  end

  def self.is_64_bit?
    not (cpu_type =~ /x86_64/).nil?
  end

  def self.bits
    Hardware.is_64_bit? ? 64 : 32
  end
end
