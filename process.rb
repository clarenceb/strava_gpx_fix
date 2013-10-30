require 'rubygems'
require 'time'
require 'nokogiri'

# GPX file to be fixed should look like this:
#
# <?xml version="1.0" encoding="UTF-8"?>
# <gpx
#   version="1.1"
#   creator="RunKeeper - http://www.runkeeper.com"
#   xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
#   xmlns="http://www.topografix.com/GPX/1/1"
#   xsi:schemaLocation="http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd"
#   xmlns:gpxtpx="http://www.garmin.com/xmlschemas/TrackPointExtension/v1">
# <trk>
#   <name><![CDATA[Running 10/26/13 5:09 pm]]></name>
#   <time>2013-10-26T17:09:25Z</time>
# <trkseg>
# <trkpt lat="-37.787065000" lon="144.770917000"><ele>54.0</ele><time>2013-10-26T17:09:25Z</time></trkpt>
# ..more points..
# </trkseg>
# </trk>
# </gpx>
#
# Here the start time was at 5:09pm but Strava will think it was at 4:09am (due to UTC + 11).
# This code will update the times so that Strava displays the correct local times. 

filename = ARGV[0] if ARGV.length > 0
offset = ARGV[1] if ARGV.length > 1

def usage message
    puts message
    puts "Usage: #{__FILE__} <gpx_filename> <offset_from_utc>"
    exit 1
end

def convert_to_utc(time_iso8601, offset)
    (Time.parse(time_iso8601) - Time.zone_offset(offset)).iso8601
end 

def process_gpx_file(filename, offset, &block)
  f = File.open(filename)
  doc = Nokogiri::XML(f)
  block.call(doc, offset)
  f.close
  doc
end

def process_track_start_time(doc, offset)
  track_time = doc.css("gpx trk > time")
  track_time.first.content = convert_to_utc(track_time.text, offset)
  doc
end

def  process_track_point_times(doc, offset)
  times = doc.css('trkpt time')
  times.each do |time|
      local_time = time.text
      time.content = convert_to_utc(local_time, offset)
  end
  doc
end

def write_processed_gpx_file(processed_filename, doc)
  File.open(processed_filename, 'w') { |f| f.write(doc) }
end    

usage("You need to specify the gpx_filename") if filename.nil? || filename.empty?
usage("You need to specify the offset_from_utc") if offset.nil? || offset.empty?

puts "GPX FIX - Processing..."
puts "  Filename = #{filename}"
puts "  Offset = #{offset}"

updated_doc = process_gpx_file(filename, offset) do |doc, offset|
  updated_doc = process_track_start_time(doc, offset)
  process_track_point_times(updated_doc, offset)
end

processed_filename = "processed-#{filename}"
write_processed_gpx_file(processed_filename, updated_doc)
puts "Done - Wrote file: #{processed_filename}"

