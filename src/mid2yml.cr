require "toka"
require "./midi_file/file"

class Options
  Toka.mapping({
    output: {
      type:        String,
      default:     "output.yml",
      description: "Output YAML file",
      value_name:  "output.yml",
    },
  }, {
    banner: "Usage: mid2yml <file>",
  })
end

opts = Options.new
if opts.positional_options.size != 1
  puts "Error: must specify exactly one input file"
  exit 1
end

input_filename = opts.positional_options.first
output_filename = opts.output

puts "Converting #{input_filename} to #{output_filename}..."

# midi_file = File.open(input_filename) { |f| f.read_bytes(MIDIFile::File) }

# puts midi_file

# midi_file.tracks.each_with_index do |track, i|
#   puts "Track #{i + 1}, Event Count: #{track.events.size}}"
#   track.events.each do |event|
#     puts event
#   end
# end

midi_file = MIDIFile::File.new

track = MIDIFile::Track.new
track.events << MIDIFile::MetaEvent.track_name(0, "Master")
track.events << MIDIFile::MetaEvent.instrument_name(0, "Master")
track.events << MIDIFile::MetaEvent.set_tempo(0, (60_000_000 / 150).to_u32)
track.events << MIDIFile::MetaEvent.end_of_track(0)
midi_file.tracks << track

track = MIDIFile::Track.new
track.events << MIDIFile::MetaEvent.track_name(0, "Piano")
track.events << MIDIFile::MetaEvent.instrument_name(0, "Piano")
track.events << MIDIFile::StatusEvent.program(0, 0, 0)
track.events << MIDIFile::StatusEvent.control(0, 0, 7, 100)
track.events << MIDIFile::StatusEvent.control(0, 0, 10, 64)
track.events << MIDIFile::StatusEvent.control(0, 0, 11, 127)
track.events << MIDIFile::StatusEvent.control(0, 0, 64, 0)
track.events << MIDIFile::StatusEvent.note_on(0, 0, 60, 100)
track.events << MIDIFile::StatusEvent.note_on(0, 0, 64, 100)
track.events << MIDIFile::StatusEvent.note_on(0, 0, 67, 100)
track.events << MIDIFile::StatusEvent.note_off(480, 0, 60, 100)
track.events << MIDIFile::StatusEvent.note_off(0, 0, 64, 100)
track.events << MIDIFile::StatusEvent.note_off(0, 0, 67, 100)
track.events << MIDIFile::MetaEvent.end_of_track(0)
midi_file.tracks << track

track = MIDIFile::Track.new
track.events << MIDIFile::MetaEvent.track_name(0, "Drums")
track.events << MIDIFile::MetaEvent.instrument_name(0, "Drums")
track.events << MIDIFile::StatusEvent.program(0, 9, 0)
track.events << MIDIFile::StatusEvent.control(0, 9, 7, 100)
track.events << MIDIFile::StatusEvent.control(0, 9, 10, 64)
track.events << MIDIFile::StatusEvent.control(0, 9, 11, 127)
track.events << MIDIFile::StatusEvent.control(0, 9, 64, 0)
track.events << MIDIFile::StatusEvent.note_on(0, 9, 36, 100)
track.events << MIDIFile::StatusEvent.note_off(120, 9, 36, 100)
track.events << MIDIFile::StatusEvent.note_on(0, 9, 36, 100)
track.events << MIDIFile::StatusEvent.note_off(120, 9, 36, 100)
track.events << MIDIFile::StatusEvent.note_on(0, 9, 38, 100)
track.events << MIDIFile::StatusEvent.note_off(120, 9, 38, 100)
track.events << MIDIFile::StatusEvent.note_on(0, 9, 36, 100)
track.events << MIDIFile::StatusEvent.note_off(120, 9, 36, 100)
track.events << MIDIFile::StatusEvent.note_on(0, 9, 36, 100)
track.events << MIDIFile::StatusEvent.note_off(120, 9, 36, 100)
track.events << MIDIFile::StatusEvent.note_on(0, 9, 36, 100)
track.events << MIDIFile::StatusEvent.note_off(120, 9, 36, 100)
track.events << MIDIFile::StatusEvent.note_on(0, 9, 38, 100)
track.events << MIDIFile::StatusEvent.note_off(120, 9, 38, 100)
track.events << MIDIFile::MetaEvent.end_of_track(0)
midi_file.tracks << track

File.open("./test.mid", "w") { |f| f.write_bytes(midi_file) }
