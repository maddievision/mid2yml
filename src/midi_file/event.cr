require "bindata"
require "./common"
require "./status_event"
require "./meta_event"
require "./sysex_event"

module MIDIFile
  class Event < BinData
    endian :big

    custom delta : VLQ = VLQ.new
    uint8 :event_head

    def to_s(io)
      io << "#{self.class.name} #{event_head.to_s(16)} #{delta}"
    end

    def self.from_io_with_running_status(io, byte_format : IO::ByteFormat, running_status : StatusEvent?)
      start_pos = io.pos
      event = self.from_io(io, byte_format)

      if event.event_head < 0x80
        io.pos = io.pos - 1
        return StatusEvent.from_io_with_running_status(io, byte_format, running_status, event.delta)
      end

      io.pos = start_pos

      case event.event_head
      when 0x80..0xEF
        StatusEvent.from_io(io, byte_format)
      when 0xF0, 0xF7
        SysexEvent.from_io(io, byte_format)
      when 0xFF
        MetaEvent.from_io(io, byte_format)
      else
        raise "Unknown event head: %02X" % event.event_head
      end
    end
  end
end
