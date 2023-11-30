require "bindata"

module MIDIFile
  class VLQ < BinData
    endian :big

    variable_array bytes : UInt8, read_next: ->{ bytes.size == 0 || bytes[-1] & 0x80 == 0x80 }

    def value
      value = 0
      bytes.each do |b|
        value = (value << 7) | (b & 0x7F)
      end
      value
    end

    def apply(value)
      new_bytes = [] of UInt8
      while value > 0
        b = value & 0x7F
        value >>= 7
        b |= 0x80 if value > 0
        new_bytes.unshift(b)
      end
      bytes = new_bytes
    end

    def to_s(io)
      io << "#{self.class.name}(#{value})"
    end
  end
end
