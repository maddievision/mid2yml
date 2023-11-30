require "bindata"
require "./common"
require "./event"

module MIDIFile
  class Track < BinData
    property events : Array(Event) = [] of Event

    endian :big

    string :chunk_header, length: ->{ 4 }, value: ->{ "MTrk" }, verify: ->{ chunk_header == "MTrk" }
    uint32 :chunk_length
    bytes :data, length: ->{ chunk_length }

    def self.from_io(io, byte_format)
      track = super
      track.parse_events
      track
    end

    def parse_events
      events = [] of Event
      io = IO::Memory.new(data)
      event_buffer = IO::Memory.new(64)
      last_status = 0_u8
      loop do
        event_buffer.clear
        status = last_status
        data1 = 0_u8
        data2 = 0_u8

        event_start = io.pos

        vlq = io.read_bytes(VLQ)

        event_head = io.read_byte

        if event_head == nil
          raise "Unexpected end of track"
        end

        event_head = event_head.not_nil!

        if event_head < 0x80
          event_head = last_status
          io.pos = io.pos - 1
        else
          event_buffer.write_byte(event_head)
          last_status = event_head
        end

        if event_head == 0xFF
          io.pos = event_start
          event = io.read_bytes(MetaEvent)
          events << event
          last_status = 0_u8

          if event.type == MetaEvent::Type::EndOfTrack
            break
          end
        elsif event_head == 0xF0 || event_head == 0xF7
          io.pos = event_start
          event = io.read_bytes(SysexEvent)
          events << event
          last_status = 0_u8
        elsif event_head >= 0xF0
          raise "Invalid status byte #{event_head}"
        elsif event_head >= 0x80
          event_buffer.write_bytes(vlq)
          event_buffer.write_byte(event_head)
          data_byte = io.read_byte
          raise "Unexpected end of track" if data_byte == nil
          event_buffer.write_byte(data_byte.not_nil!)
          if event_head >> 4 != StatusEvent::Type::Program && event_head >> 4 != StatusEvent::Type::ChannelPressure
            data_byte = io.read_byte
            raise "Unexpected end of track" if data_byte == nil
            event_buffer.write_byte(data_byte.not_nil!)
          end

          event_buffer.rewind

          event = event_buffer.read_bytes(StatusEvent)
          events << event
        end
      end

      if io.pos != chunk_length
        raise "Parsed size #{io.pos} does not match chunk length #{chunk_length}"
      end
      @events = events
    end
  end
end
