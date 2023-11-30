require "bindata"
require "./common"

module MIDIFile
  class Event < BinData; end;
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

    DATA_SIZES = {
      Type::NoteOff         => 2,
      Type::NoteOn          => 2,
      Type::NotePressure    => 2,
      Type::Control         => 2,
      Type::Program         => 1,
      Type::ChannelPressure => 1,
      Type::PitchBend       => 2,
    }

    uint8 :data1
    uint8 :data2, onlyif: ->{ DATA_SIZES[type] > 1 }

    def type
      @type ||= Type.new(event_head >> 4)
    end

    def channel
      @channel ||= event_head & 0x0F
    end

    def type=(new_type : Type)
      @type = new_type
      self.event_head = (event_head & 0x0F) | (new_type.value << 4)
    end

    def channel=(new_channel : UInt8)
      @channel = new_channel
      self.event_head = (event_head & 0xF0) | (new_channel & 0x0F)
    end

    def event_data # TODO make subclasses maybe?
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
      io << "#{self.class.name} Delta: #{delta} Type: #{type} Channel: #{channel} #{event_data}"
    end

    @@running_status_buffer = IO::Memory.new(8) # not thread-safe…

    def self.from_io_with_running_status(io, byte_format : IO::ByteFormat, running_status : StatusEvent?, delta : VLQ)
      if !running_status
        raise "No running status given"
      end

      rs_io = @@running_status_buffer
      rs_io.rewind

      rs_io.write_bytes(delta)
      rs_io.write_byte(running_status.event_head)
      size = DATA_SIZES[running_status.type]
      (0...size).each do
        data = io.read_byte
        raise "End of file reached while parsing event" if !data
        rs_io.write_byte(data)
      end
      rs_io.rewind

      self.from_io(rs_io, byte_format)
    end

    def to_io_with_running_status(io, byte_format : IO::ByteFormat, running_status : StatusEvent?)
      io.write_bytes(delta)
      if !running_status || running_status.type != type || running_status.channel != channel
        io.write_byte(event_head)
      end
      io.write_bytes(data1)
      io.write_bytes(data2) if DATA_SIZES[type] > 1
    end

    def self.note_on(delta : UInt32, channel : UInt8, note : UInt8, velocity : UInt8)
      self.new.tap { |e| e.delta = VLQ.from_value(delta); e.type = Type::NoteOn; e.channel = channel; e.data1 = note; e.data2 = velocity }
    end

    def self.note_off(delta : UInt32, channel : UInt8, note : UInt8, velocity : UInt8)
      self.new.tap { |e| e.delta = VLQ.from_value(delta); e.type = Type::NoteOff; e.channel = channel; e.data1 = note; e.data2 = velocity }
    end

    def self.note_pressure(delta : UInt32, channel : UInt8, note : UInt8, pressure : UInt8)
      self.new.tap { |e| e.delta = VLQ.from_value(delta); e.type = Type::NotePressure; e.channel = channel; e.data1 = note; e.data2 = pressure }
    end

    def self.control(delta : UInt32, channel : UInt8, number : UInt8, value : UInt8)
      self.new.tap { |e| e.delta = VLQ.from_value(delta); e.type = Type::Control; e.channel = channel; e.data1 = number; e.data2 = value }
    end

    def self.program(delta : UInt32, channel : UInt8, program : UInt8)
      self.new.tap { |e| e.delta = VLQ.from_value(delta); e.type = Type::Program; e.channel = channel; e.data1 = program }
    end

    def self.channel_pressure(delta : UInt32, channel : UInt8, pressure : UInt8)
      self.new.tap { |e| e.delta = VLQ.from_value(delta); e.type = Type::ChannelPressure; e.channel = channel; e.data1 = pressure }
    end

    def self.pitch_bend(delta : UInt32, channel : UInt8, value : UInt16)
      self.new.tap { |e| e.delta = VLQ.from_value(delta); e.type = Type::PitchBend; e.channel = channel; e.data1 = value & 0x7F; e.data2 = (value >> 7) & 0x7F }
    end
  end
end
