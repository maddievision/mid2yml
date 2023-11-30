require "./spec_helper"

describe MIDIFile::VLQ do
  it "should decode a single byte VLQ" do
    io = IO::Memory.new
    io.write_byte 0x00
    io.rewind

    vlq = io.read_bytes(MIDIFile::VLQ)
    vlq.bytes.should eq([0x00])
    vlq.value.should eq(0)

    io.rewind
    io.write_byte 0x7F
    io.rewind

    vlq = io.read_bytes(MIDIFile::VLQ)
    vlq.bytes.should eq([0x7F])
    vlq.value.should eq(0x7F)
  end

  it "should decode a 2-byte VLQ" do
    io = IO::Memory.new
    io.write_byte 0x81
    io.write_byte 0x30
    io.rewind

    vlq = io.read_bytes(MIDIFile::VLQ)
    vlq.bytes.should eq([0x81, 0x30])
    vlq.value.should eq(0xB0)

    io.rewind
    io.write_byte 0xA3
    io.write_byte 0x7F
    io.rewind

    vlq = io.read_bytes(MIDIFile::VLQ)
    vlq.bytes.should eq([0xA3, 0x7F])
    vlq.value.should eq(0x11FF)
  end

  it "should decode a 3-byte VLQ" do
    io = IO::Memory.new
    io.write_byte 0xC5
    io.write_byte 0x84
    io.write_byte 0x32
    io.rewind

    vlq = io.read_bytes(MIDIFile::VLQ)
    vlq.bytes.should eq([0xC5, 0x84, 0x32])
    vlq.value.should eq(0x114232)
  end

  it "should decode a 4-byte VLQ" do
    io = IO::Memory.new
    io.write_byte 0xE2
    io.write_byte 0xA2
    io.write_byte 0xB2
    io.write_byte 0x72
    io.rewind

    vlq = io.read_bytes(MIDIFile::VLQ)
    vlq.bytes.should eq([0xE2, 0xA2, 0xB2, 0x72])
    vlq.value.should eq(0xC489972)
  end

  it "should not parse anything pass a byte with an unset MSB" do
    io = IO::Memory.new
    io.write_byte 0x81
    io.write_byte 0x02
    io.write_byte 0x04
    io.write_byte 0x80
    io.rewind

    vlq = io.read_bytes(MIDIFile::VLQ)
    vlq.bytes.should eq([0x81, 0x02])
    vlq.value.should eq(0x82)
  end

  it "should fail to parse if there are no bytes following a byte with the MSB set" do
    io = IO::Memory.new
    io.write_byte 0x81
    io.rewind

    expect_raises(BinData::ParseError) { io.read_bytes(MIDIFile::VLQ) }
  end
end
