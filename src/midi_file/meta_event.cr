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
          denominator:                2 ** data[1],
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
  end
end
