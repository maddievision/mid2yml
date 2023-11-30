require "./spec_helper"

describe MIDIFile::File do
  it "should parse a Format 0 MIDI file" do
    io = IO::Memory.new
    write_chunk_with_length(io, "MThd", 6)
    io.write_bytes 0_u16, IO::ByteFormat::BigEndian
    io.write_bytes 1_u16, IO::ByteFormat::BigEndian
    io.write_bytes 480_u16, IO::ByteFormat::BigEndian

    write_chunk_with_length(io, "MTrk", 4)
    write_eot_event(io)
    io.rewind

    f = io.read_bytes(MIDIFile::File)
    f.chunk_header.should eq("MThd")
    f.chunk_length.should eq(6)
    f.format.should eq(MIDIFile::File::Format::SingleTrack)
    f.track_count.should eq(1)
    f.tracks.size.should eq(1)
    f.ppqn.should eq(480)
  end

  it "should parse a Format 1 MIDI file" do
    io = IO::Memory.new

    write_chunk_with_length(io, "MThd", 6)
    io.write_bytes 1_u16, IO::ByteFormat::BigEndian
    io.write_bytes 2_u16, IO::ByteFormat::BigEndian
    io.write_bytes 480_u16, IO::ByteFormat::BigEndian
    (0..2).each do
      write_chunk_with_length(io, "MTrk", 4)
      write_eot_event(io)
    end
    io.rewind

    f = io.read_bytes(MIDIFile::File)
    f.chunk_header.should eq("MThd")
    f.chunk_length.should eq(6)
    f.format.should eq(MIDIFile::File::Format::MultiTrack)
    f.track_count.should eq(2)
    f.tracks.size.should eq(2)
    f.ppqn.should eq(480)
  end

  it "should parse a Format 2 MIDI file" do
    io = IO::Memory.new

    write_chunk_with_length(io, "MThd", 6)
    io.write_bytes 2_u16, IO::ByteFormat::BigEndian
    io.write_bytes 2_u16, IO::ByteFormat::BigEndian
    io.write_bytes 480_u16, IO::ByteFormat::BigEndian
    (0..2).each do
      write_chunk_with_length(io, "MTrk", 4)
      write_eot_event(io)
    end
    io.rewind

    f = io.read_bytes(MIDIFile::File)
    f.chunk_header.should eq("MThd")
    f.chunk_length.should eq(6)
    f.format.should eq(MIDIFile::File::Format::MultiSong)
    f.track_count.should eq(2)
    f.tracks.size.should eq(2)
    f.ppqn.should eq(480)
  end

  it "should reject a MIDI file with an invalid header" do
    io = IO::Memory.new

    write_chunk_with_length(io, "MLol", 6)
    io.write_bytes 0_u16, IO::ByteFormat::BigEndian
    io.write_bytes 1_u16, IO::ByteFormat::BigEndian
    io.write_bytes 480_u16, IO::ByteFormat::BigEndian

    write_chunk_with_length(io, "MTrk", 4)
    write_eot_event(io)
    io.rewind

    expect_raises(BinData::VerificationException) { io.read_bytes(MIDIFile::File) }
  end

  it "should fail to parse a MIDI file with an invalid format" do
    io = IO::Memory.new

    write_chunk_with_length(io, "MThd", 6)
    io.write_bytes 3_u16, IO::ByteFormat::BigEndian
    io.write_bytes 1_u16, IO::ByteFormat::BigEndian
    io.write_bytes 480_u16, IO::ByteFormat::BigEndian

    write_chunk_with_length(io, "MTrk", 4)
    write_eot_event(io)
    io.rewind

    expect_raises(BinData::ParseError) { io.read_bytes(MIDIFile::File) }
  end

  it "should reject a Format 0 MIDI File that has more than one track" do
    io = IO::Memory.new

    write_chunk_with_length(io, "MThd", 6)
    io.write_bytes 0_u16, IO::ByteFormat::BigEndian
    io.write_bytes 2_u16, IO::ByteFormat::BigEndian
    io.write_bytes 480_u16, IO::ByteFormat::BigEndian

    (0..2).each do
      write_chunk_with_length(io, "MTrk", 4)
      write_eot_event(io)
    end
    io.rewind

    expect_raises(BinData::ReadingVerificationException) { io.read_bytes(MIDIFile::File) }
  end

  it "should fail to parse a MIDI file that has less tracks then specified in the header" do
    io = IO::Memory.new

    write_chunk_with_length(io, "MThd", 6)
    io.write_bytes 1_u16, IO::ByteFormat::BigEndian
    io.write_bytes 2_u16, IO::ByteFormat::BigEndian
    io.write_bytes 480_u16, IO::ByteFormat::BigEndian

    write_chunk_with_length(io, "MTrk", 4)
    write_eot_event(io)
    io.rewind

    expect_raises(BinData::ParseError) { io.read_bytes(MIDIFile::File) }
  end
end
