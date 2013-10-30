require 'rubygems'
require 'time'
require 'nokogiri'

filename = ARGV[0] if ARGV.length > 0
offset = ARGV[1] if ARGV.length > 1
newfilename = "processed-#{filename}"

puts "Filename = #{filename}"
puts "Offset = #{offset}"

def convert_to_utc(time_iso8601, offset)
    (Time.parse(time_iso8601) - Time.zone_offset(offset)).iso8601
end 

# <trkpt lat="-37.787063000" lon="144.770933000"><ele>54.0</ele><time>2013-01-02T21:03:41Z</time></trkpt>

puts "Processing - #{filename}"
f = File.open(filename)
doc = Nokogiri::XML(f)
track_time = doc.css("gpx trk > time")
track_time.first.content = convert_to_utc(track_time.text, offset)
times = doc.css('trkpt time')
times.each do |time|
    local_time = time.text
    time.content = convert_to_utc(local_time, offset)
end
f.close
File.open(newfilename, 'w') { |f| f.write(doc) }
puts "Done - Wrote file: #{newfilename}"

