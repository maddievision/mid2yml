require "bindata"
require "./common"

module MIDIFile
  class Event < BinData; end;
  class SysexEvent < Event
    custom length : VLQ = VLQ.new
    bytes :data, length: ->{ length.value }

    property buf : IO::Memory = IO::Memory.new(4)

    def is_continued?
      event_head == 0xF7
    end

    def has_more?
      data[-1] != 0xF7
    end

    def to_s(io)
      io << "#{self.class.name} Delta: #{delta} Length: #{length} #{is_continued? ? "continued" : "complete"} #{has_more? ? "has more" : "last"}"
    end

    def self.from_data(delta : UInt32, data : Bytes, is_continuation = false)
      self.new.tap do |e|
        e.event_head = is_continuation ? 0xF7 : 0xF0
        e.delta = VLQ.from_value(delta)
        e.length = VLQ.from_value(data.size)
        e.data = data
      end
    end
  end
end
