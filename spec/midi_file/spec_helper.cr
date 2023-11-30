require "spec"
require "bindata"
require "../../src/midi_file/file"

def write_chunk_with_length(io, header, length : UInt32)
  io.write_string header.encode("ASCII")
  io.write_bytes length, IO::ByteFormat::BigEndian
end

def write_eot_event(io)
  io.write_bytes 0x00_u8
  io.write_bytes 0xFF_u8
  io.write_bytes 0x2F_u8
  io.write_bytes 0x00_u8
end
