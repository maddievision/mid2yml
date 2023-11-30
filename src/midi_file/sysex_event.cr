require "bindata"
require "./common"

module MIDIFile
  class Event < BinData; end;
  class SysexEvent < Event
    custom length : VLQ = VLQ.new
    bytes :data, length: ->{ length.value }

    def is_continued?
      event_head == 0xF7
    end

    def has_more?
      data[-1] != 0xF7
    end

    def to_s(io)
      io << "#{self.class.name} Delta: #{delta} Length: #{length} #{is_continued? ? "continued" : "complete"} #{has_more? ? "has more" : "last"}"
    end
  end
end
