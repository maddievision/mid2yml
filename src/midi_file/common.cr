require "bindata"

module MIDIFile
  class VLQ < BinData
    endian :big

    variable_array bytes : UInt8, read_next: ->{ bytes.size == 0 || bytes[-1] & 0x80 == 0x80 }

    def value
      out_value = 0
      bytes.each do |b|
        out_value = (out_value << 7) | (b & 0x7F)
      end
      out_value
    end

    def value=(new_value : UInt32)
      new_bytes = [] of UInt8
      m = 0
      loop do
        b = (new_value & 0x7F) | m
        new_bytes.unshift(b.to_u8)
        new_value >>= 7
        break if new_value == 0

        m = 0x80
      end
      self.bytes = new_bytes
    end

    def to_s(io)
      io << "#{self.class.name}(#{value})"
    end

    def self.from_value(new_value : UInt32)
      vlq = self.new
      vlq.value = new_value
      vlq
    end
  end
end
