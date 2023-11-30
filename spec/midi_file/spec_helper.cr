require "spec"
require "bindata"
require "../../src/midi_file/file"

def write_chunk_with_size(io, id, size : UInt32)
  io.write_string id.encode("ASCII")
  io.write_bytes size, IO::ByteFormat::BigEndian
end

def write_eot_event(io)
  io.write_bytes 0x00_u8
  io.write_bytes 0xFF_u8
  io.write_bytes 0x2F_u8
  io.write_bytes 0x00_u8
end
