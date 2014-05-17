require 'timezone'
require 'nokogiri'
require 'fileutils'
require 'yaml'

# GPX file(s) to be fixed should look like this:
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

gpx_source = ARGV[0] if ARGV.length > 0
offset_from_utc = ARGV[1] if ARGV.length > 1

OUTPUT_DIR = 'processed'
CONFIG_FILE = 'config.yaml'

def usage(message)
    puts message
    puts
    puts "Usage: #{__FILE__} <gpx_source> <offset_from_utc>"
    puts "gpx_source       A GPX filename or a directory containing multiple GPX files."
    puts "offset_from_utc  The timezone offset for where the run(s) took place"
    puts "                 (leave empty if there are a mix of timezones inside a GPX source directory)"
    exit 1
end

def directory_mode? gpx_source
  File.directory? gpx_source
end

def configure_geonames_service
  geoname_username = YAML.load(File.read(CONFIG_FILE))['geonames_username']
  raise "No geonames username found in file: #{CONFIG_FILE}" unless geoname_username
  if geoname_username
    Timezone::Configure.begin do |c|
      c.username = geoname_username
    end
    puts "Configured to use GeoNames Webservice with username: #{geoname_username}"
  end
end

def calculate_timezone_offset(doc, offset)
  if offset
    puts " ... Using Fixed Timezone Offset"
    zone_offset = Time.zone_offset(offset)
  else
    puts " ... Calculating Timezone Offset using track Lat/Lon position"
    first_track_point = doc.css('trkpt').first
    first_track_time = doc.css("trkpt > time").first.text
    lat = first_track_point['lat']
    lon = first_track_point['lon']
    puts " ... Lat: #{lat}, Lon: #{lon}, Time: #{first_track_time}"
    timezone = Timezone::Zone.new :lat => lat, :lon => lon
    puts " ... GPX file timezone is #{timezone.zone}"
    dst = timezone.dst?(Time.iso8601(first_track_time.chop))
    zone_offset = timezone.utc_offset + (dst ? 3600 : 0)
  end
  puts " ... Timezone Offset (Seconds): #{zone_offset}"
  zone_offset
end

def convert_to_utc(time_iso8601, zone_offset)
    (Time.parse(time_iso8601) - zone_offset).iso8601
end

def process_gpx_file(filename, offset, &block)
  f = nil; doc = nil
  begin
    f = File.open(filename)
    doc = Nokogiri::XML(f)
    file_offset = calculate_timezone_offset(doc, offset)
    block.call(doc, file_offset)
  rescue => e
    $stderr.puts e.message
  end
  f.close if f
  doc
end

def fix_track_start_time(doc, zone_offset)
  track_time = doc.css("gpx trk > time")
  puts " ... Track Start Time (Original) #{track_time.text}"
  track_time.first.content = convert_to_utc(track_time.text, zone_offset)
  puts " ... Track Start Time (Fixed) #{track_time.text}"
  doc
end

def fix_track_point_times(doc, zone_offset)
  times = doc.css('trkpt time')
  times.each do |time|
      local_time = time.text
      time.content = convert_to_utc(local_time, zone_offset)
  end
  doc
end

def write_processed_gpx_file(processed_filename, doc)
  File.open(processed_filename, 'w') { |f| f.write(doc) }
end

usage("You need to specify the gpx_source") if gpx_source.nil? || gpx_source.empty?

puts "STRAVA GPX FIX - Processing..."
puts "  #{directory_mode?(gpx_source) ? "Directory" : "     File"}: #{gpx_source}"
puts "     Offset: #{offset_from_utc}"

if directory_mode? gpx_source
  files = Dir.glob(File.join(gpx_source, '*.gpx'))
else
  files = [gpx_source]
end

configure_geonames_service unless offset_from_utc

FileUtils.mkdir_p OUTPUT_DIR
Dir.glob(File.join(OUTPUT_DIR, "*.gpx")).each { |processed_file| FileUtils.rm processed_file }

files.each do |filename|
  puts "Processing GPX file: #{filename}"
  fixed_doc = process_gpx_file(filename, offset_from_utc) do |doc, zone_offset|
    updated_doc = fix_track_start_time(doc, zone_offset)
    fix_track_point_times(updated_doc, zone_offset)
  end

  processed_filename = File.join(OUTPUT_DIR, "processed-#{File.basename(filename)}")
  write_processed_gpx_file(processed_filename, fixed_doc)
  puts " ... Wrote file: #{processed_filename}"
end

puts "Processed #{files.size} files."
puts "Done."
