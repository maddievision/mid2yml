require "bindata"
require "./common"

module MIDIFile
  class Event < BinData; end;
  class MetaEvent < Event
    enum Type
      SequenceNumber    = 0x00
      Text              = 0x01
      CopyrightNotice   = 0x02
      TrackName         = 0x03
      InstrumentName    = 0x04
      Lyrics            = 0x05
      Marker            = 0x06
      CuePoint          = 0x07
      ChannelPrefix     = 0x20
      EndOfTrack        = 0x2F
      SetTempo          = 0x51
      SMPTEOffset       = 0x54
      TimeSignature     = 0x58
      KeySignature      = 0x59
      SequencerSpecific = 0x7F
    end

    enum_field UInt8, type : Type = Type::EndOfTrack
    custom length : VLQ = VLQ.new
    bytes :data, length: ->{ length.value }
    property buf : IO::Memory = IO::Memory.new(4)

    def event_data
      case type
      when Type::SequenceNumber
        {
          number: (data[0] << 8) | data[1],
        }
      when Type::Text, Type::TrackName, Type::InstrumentName, Type::Lyrics, Type::Marker, Type::CuePoint
        {
          text: String.new(data),
        }
      when Type::ChannelPrefix
        {
          channel: data[0],
        }
      when Type::EndOfTrack
        {
          no_data: true,
        }
      when Type::SetTempo
        {
          microseconds_per_quarter: (data[0].to_u32 << 16) | (data[1].to_u32 << 8) | data[2].to_u32,
        }
      when Type::SMPTEOffset
        {
          hours:     data[0], # todo: parse frame rate out of here
          minutes:   data[1],
          seconds:   data[2],
          frames:    data[3],
          subframes: data[4],
        }
      when Type::TimeSignature
        {
          numerator:                  data[0],
          denominator:                data[1],
          clocks_per_click:           data[2],
          thirty_seconds_per_quarter: data[3],
        }
      when Type::KeySignature
        {
          key:   data[0],
          scale: data[1],
        }
      when Type::SequencerSpecific
        {
          data: data,
        }
      else
        {
          data: data,
        }
      end
    end

    def to_s(io)
      io << "#{self.class.name} Delta: #{delta} Type: #{type} Length: #{length} #{event_data}"
    end

    def self.sequence_number(delta : UInt32, number : UInt16)
      self.new.tap do |e|
        e.delta = VLQ.from_value(delta)
        e.type = Type::SequenceNumber
        e.buf.write_byte(((number >> 8) & 0xFF).to_u8)
        e.buf.write_byte((number & 0xFF).to_u8)
        e.data = e.buf.to_slice
      end
    end

    def self.text(delta : UInt32, text : String)
      self.new.tap { |e| e.event_head = 0xFF; e.delta = VLQ.from_value(delta); e.type = Type::Text; e.data = text.encode("UTF-8") }
    end

    def self.track_name(delta : UInt32, name : String)
      self.new.tap { |e| e.event_head = 0xFF; e.delta = VLQ.from_value(delta); e.type = Type::TrackName; e.data = name.encode("UTF-8") }
    end

    def self.instrument_name(delta : UInt32, name : String)
      self.new.tap { |e| e.event_head = 0xFF; e.delta = VLQ.from_value(delta); e.type = Type::InstrumentName; e.data = name.encode("UTF-8") }
    end

    def self.lyrics(delta : UInt32, lyrics : String)
      self.new.tap { |e| e.event_head = 0xFF; e.delta = VLQ.from_value(delta); e.type = Type::Lyrics; e.data = lyrics.encode("UTF-8") }
    end

    def self.marker(delta : UInt32, marker : String)
      self.new.tap { |e| e.event_head = 0xFF; e.delta = VLQ.from_value(delta); e.type = Type::Marker; e.data = marker.encode("UTF-8") }
    end

    def self.cue_point(delta : UInt32, cue_point : String)
      self.new.tap { |e| e.event_head = 0xFF; e.delta = VLQ.from_value(delta); e.type = Type::CuePoint; e.data = cue_point.encode("UTF-8") }
    end

    def self.channel_prefix(delta : UInt32, channel : UInt8)
      self.new.tap do |e|
        e.event_head = 0xFF
        e.delta = VLQ.from_value(delta)
        e.type = Type::ChannelPrefix
        e.buf.write_byte(channel)
        e.data = e.buf.to_slice
      end
    end

    def self.end_of_track(delta : UInt32)
      self.new.tap { |e| e.event_head = 0xFF; e.delta = VLQ.from_value(delta); e.type = Type::EndOfTrack; e.data = e.buf.to_slice }
    end

    def self.set_tempo(delta : UInt32, microseconds_per_quarter : UInt32)
      self.new.tap do |e|
        e.event_head = 0xFF
        e.delta = VLQ.from_value(delta)
        e.type = Type::SetTempo
        e.buf.write_byte(((microseconds_per_quarter >> 16) & 0xFF).to_u8)
        e.buf.write_byte(((microseconds_per_quarter >> 8) & 0xFF).to_u8)
        e.buf.write_byte((microseconds_per_quarter & 0xFF).to_u8)
        e.data = e.buf.to_slice
      end
    end

    def self.smpte_offset(delta : UInt32, hours : UInt8, minutes : UInt8, seconds : UInt8, frames : UInt8, subframes : UInt8)
      self.new.tap do |e|
        e.event_head = 0xFF
        e.delta = VLQ.from_value(delta)
        e.type = Type::SMPTEOffset
        e.buf.write_byte(hours)
        e.buf.write_byte(minutes)
        e.buf.write_byte(seconds)
        e.buf.write_byte(frames)
        e.buf.write_byte(subframes)
        e.data = e.buf.to_slice
      end
    end

    def self.time_signature(delta : UInt32, numerator : UInt8, denominator : UInt8, clocks_per_click : UInt8, thirty_seconds_per_quarter : UInt8)
      self.new.tap do |e|
        e.event_head = 0xFF
        e.delta = VLQ.from_value(delta)
        e.type = Type::TimeSignature
        e.buf.write_byte(numerator)
        e.buf.write_byte(denominator)
        e.buf.write_byte(clocks_per_click)
        e.buf.write_byte(thirty_seconds_per_quarter)
        e.data = e.buf.to_slice
      end
    end

    def self.key_signature(delta : UInt32, key : UInt8, scale : UInt8)
      self.new.tap do |e|
        e.event_head = 0xFF
        e.delta = VLQ.from_value(delta)
        e.type = Type::KeySignature
        e.buf.write_byte(key)
        e.buf.write_byte(scale)
        e.data = e.buf.to_slice
      end
    end

    def to_io(io, byte_format : IO::ByteFormat)
      self.event_head = 0xFF
      self.length = VLQ.from_value(self.data.size.to_u32)
      super
    end
  end
end
