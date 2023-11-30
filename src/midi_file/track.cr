require "bindata"
require "./common"
require "./event"

module MIDIFile
  class Track < BinData
    property events : Array(Event) = [] of Event

    endian :big

    string :chunk_id, length: ->{ 4 }, value: ->{ "MTrk" }, verify: ->{ chunk_id == "MTrk" }
    uint32 :chunk_size
    bytes :data, length: ->{ chunk_size }

    def self.from_io(io, byte_format : IO::ByteFormat)
      super.tap { |t| t.parse_events(byte_format) }
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
  end
end
