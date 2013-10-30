STRAVA GPX FIX
--------------

Fix GPX files (change UTC to local time) for importing to Strava after exporting from Runkeeper.
Note: Only tested with Runkeeper exported GPX files and with only 1 lap in the file.

Use this tool to fix your GPX files before uploading to Strava if you find the date/times are off.

Example usage:
1. Export GPX activity from Runkeeper
2. Run the process.rb script on it
3. Upload the adjusted version to Strava

Installation:
- You need Ruby 1.8.7+ and RubyGems
- Install bundler `gem install bundler`

How to process an exported GPX file:

  bundle exec ruby process.rb <gpx_filename> "<local_offset_from_utc>"

Example for Australian EST when the activity happend not during daylight savings:

  bundle exec ruby process.rb 2013-05-21-1105.gpx "+10"

Example for Australian EST when the activity happened during daylight savings:

  bundle exec ruby process.rb 2013-10-09-2133.gpx "+11"

