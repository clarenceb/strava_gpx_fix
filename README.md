STRAVA GPX FIX
--------------

Fix GPX files (change UTC to local time) for importing to Strava after exporting from Runkeeper.
*Note*: Only tested with Runkeeper exported GPX files and with only 1 lap in the file.

Use this tool to fix your GPX files before uploading to Strava if you find the date/times are off.

Installation:
=============

- You need Ruby 1.8.7+ and RubyGems
- Install bundler `gem install bundler`

If you want to use automatic timezone calculation then you need to add your GeoNames username to `config.yaml`:

1. Head to [http://www.geonames.org/login](GeoNames)
2. Sign up and activate your account via the email you will receive
3. After logging in, go to [http://www.geonames.org/manageaccount](Manage Account)
4. Click the [http://www.geonames.org/enablefreewebservice](Enable) link to activate free web service usage
5. Copy the file "config.yaml.template" to "config.yaml"
6. Edit the file add replavce the text `<your_username>` with your username

e.g.

`geonames_username: joebloggs`

Usage:
======

Single GPX file:
----------------

1. Log onto Runkeeper.com
2. View your activity on Runkeeper
3. Click "GPX" under the "Export" section
4. Copy the downloaded GPX file to the source directory
5. Process the file to fix the incorrect timezone offset so Strava will display the activity date/time correctly:

`bundle exec ruby convert_gpx.rb <gpx_filename> "<local_offset_from_utc>"`

or to use the GeoNames web service to figure out the timezone:

`bundle exec ruby convert_gpx.rb <gpx_filename>`

The processed file will be placed in the `processed` directory.

Multiple GPX files:
-------------------

1. Log onto Runkeeper.com
2. Go to the [http://runkeeper.com/settings](Account Settings) page
3. Click [http://runkeeper.com/exportDataForm](Export Data)
4. Enter the From: and To: dates
5. Click "Export Data"
6. After some time the "Download Now!" button will appear
7. Download the zip file
8. Unzip the contents to the `source` directory
9. Process the directory of files to fix the incorrect timezone offset so Strava will display the activity date/time correctly:

`bundle exec ruby convert_gpx.rb source "<local_offset_from_utc>"`

or to use the GeoNames web service to figure out the timezone:

`bundle exec ruby convert_gpx.rb source`

The processed files will be placed in the "processed" directory.

Examples:
=========

Example for Australian EST when the activity happend not during daylight savings:

    bundle exec ruby convert_gpx.rb 2013-05-21-1105.gpx "+10"

Example for Australian EST when the activity happened during daylight savings:

    bundle exec ruby convert_gpx.rb 2013-10-09-2133.gpx "+11"

Example for letting the script figure out the timezone based on the first track point lat/lon:

    bundle exec ruby convert_gpx.rb 2013-10-09-2133.gpx

Example for letting the script figure out the timezone based on the first track point lat/lon (directory mode):

    bundle exec ruby convert_gpx.rb source
