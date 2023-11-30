require "bindata"
require "./track"

module MIDIFile
  class File < BinData
    endian :big

    enum Format : UInt16
      SingleTrack = 0
      MultiTrack  = 1
      MultiSong   = 2
    end

    string :chunk_id, length: ->{ 4 }, value: ->{ "MThd" }, verify: ->{ chunk_id == "MThd" }
    uint32 :chunk_size, value: ->{ 6_u16 }, verify: ->{ chunk_size == 6 }
    enum_field UInt16, format : Format = Format::SingleTrack
    uint16 :track_count, verify: ->{
      case format
      when Format::SingleTrack
        track_count == 1
      when Format::MultiTrack, Format::MultiSong
        track_count > 1
      end
    }
    uint16 :ppqn, value: ->{ 480_u16 } # todo: support SMPTE
    variable_array tracks : Track, read_next: ->{ tracks.size < track_count }

    def to_s(io)
      io << "#{self.class.name} #{format} Tracks: #{track_count} PPQN: #{ppqn}"
    end
  end
end
