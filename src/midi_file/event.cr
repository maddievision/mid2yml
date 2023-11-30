require "bindata"
require "./common"

module MIDIFile
  class Event < BinData
    endian :big

    custom delta_pulses : VLQ = VLQ.new
    uint8 :event_head

    def to_s(io)
      io << "#{self.class.name} #{event_head.to_s(16)} #{delta_pulses}"
    end
  end

  class StatusEvent < Event
    enum Type
      NoteOff         = 0x8
      NoteOn          = 0x9
      NotePressure    = 0xA
      Control         = 0xB
      Program         = 0xC
      ChannelPressure = 0xD
      PitchBend       = 0xE
    end

    uint8 :data1
    uint8 :data2, onlyif: ->{ type != Type::Program && type != Type::ChannelPressure }

    def type
      @type ||= Type.new(event_head >> 4)
    end

    def channel
      @channel ||= event_head & 0x0F
    end

    def apply_type(new_type : Type)
      @type = new_type
      new_event_head = (event_head & 0x0F) | (new_type.value << 4)
      event_head = new_event_head
    end

    def apply_channel(new_channel : UInt8)
      @channel = new_channel
      new_event_head = (event_head & 0xF0) | (new_channel & 0x0F)
      event_head = new_event_head
    end

    def event_data
      case type
      when Type::NoteOff, Type::NoteOn
        {
          note:     data1,
          velocity: data2,
        }
      when Type::NotePressure
        {
          note:     data1,
          pressure: data2,
        }
      when Type::Control
        {
          number: data1,
          value:  data2,
        }
      when Type::Program
        {
          program: data1,
        }
      when Type::ChannelPressure
        {
          pressure: data1,
        }
      when Type::PitchBend
        {
          value: (data2 << 7) | data1,
        }
      end
    end

    def to_s(io)
      io << "#{self.class.name} Delta: #{delta_pulses} Type: #{type} Channel: #{channel} #{event_data}"
    end
  end

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
      io << "#{self.class.name} Delta: #{delta_pulses} Type: #{type} Length: #{length} #{event_data}"
    end
  end

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
      io << "#{self.class.name} Delta: #{delta_pulses} Length: #{length} #{is_continued? ? "continued" : "complete"} #{has_more? ? "has more" : "last"}"
    end
  end
end
