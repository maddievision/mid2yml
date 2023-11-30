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

input_file = File.open(input_filename)
midi_file = input_file.read_bytes(MIDIFile::File)

puts midi_file

midi_file.parse_events

midi_file.tracks.each_with_index do |track, i|
  puts "Track #{i + 1}, Event Count: #{track.events.size}}"
  track.events.each do |event|
    puts event
  end
end
