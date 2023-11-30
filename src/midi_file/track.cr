require "bindata"
require "./common"
require "./event"

module MIDIFile
  class Track < BinData
    property events : Array(Event) = [] of Event

    endian :big

    string :chunk_id, length: ->{ 4 }, value: ->{ "MTrk" }, verify: ->{ chunk_id == "MTrk" }
    uint32 :chunk_size, value: ->{ data.size }
    bytes :data, length: ->{ chunk_size }

    def self.from_io(io, byte_format : IO::ByteFormat)
      super.tap { |t| t.parse_events(byte_format) }
    end

    def to_io(io, byte_format : IO::ByteFormat)
      apply(byte_format)
      super
    end

    def parse_events(byte_format : IO::ByteFormat)
      events = [] of Event
      io = IO::Memory.new(data)
      last_status : StatusEvent? = nil
      loop do
        event = Event.from_io_with_running_status(io, byte_format, last_status)
        events << event

        break if event.is_a?(MetaEvent) && event.type == MetaEvent::Type::EndOfTrack

        last_status = event if event.is_a?(StatusEvent)
      end

      if io.pos != chunk_size
        raise "Parsed size #{io.pos} does not match chunk length #{chunk_size}"
      end
      @events = events
    end

    def apply(byte_format : IO::ByteFormat)
      io = IO::Memory.new(events.size * 4)
      last_status : StatusEvent? = nil
      events.each do |event|
        if event.is_a?(StatusEvent)
          event.to_io_with_running_status(io, byte_format, last_status)
          last_status = event
        else
          io.write_bytes(event)
          last_status = nil
        end
      end

      self.data = io.to_slice
      self.chunk_size = self.data.size.to_u32
    end
  end
end
