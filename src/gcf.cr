APPNAME = "gcf.cr"
APPBIN = "gcf"
POSSIBLE_MEMORY_CONFIGS = ["128 MB", "256 MB", "512 MB", "1 GB", "2 GB"]
POSSIBLE_TRIGGER_MODES = ["http", "topic", "bucket-create", "bucket-delete", "bucket-archive", "bucket-metadata-update"]
PWD = `pwd`.strip

require "./gcf/*"
require "option_parser"
require "file_utils"

def print_version
  puts ""
  puts "#{APPNAME} v#{GCF::VERSION}"
  puts ""
end

# initialize config info
project_id = ""
source_path = "."
function_name = ""
http_trigger = ""
region = "us-central1"
function_memory = "128 MB"
trigger_mode = "http"
crystal_version = "0.24.2"
bucket = ""
topic = ""

run_deploy = false

options_parser = nil

# read command line args
OptionParser.parse! do |parser|
  parser.banner = "usage: #{APPBIN} [arguments]"
  parser.on("-h", "--help", "show this help") { puts ""; puts parser; puts "" }
  parser.on("-d", "--deploy", "required to indicate that you intend to deploy") { run_deploy = true }
  parser.on("-p PROJECT", "--project PROJECT", "Google project ID, defaults to current gcloud setting") { |v| project_id = v }
  parser.on("-s PATH", "--source PATH", "path or git link to source code to be deployed, defaults to '.'") { |v| source_path = v }
  parser.on("-n NAME", "--name NAME", "cloud function name, defaults to name of directory or repo") { |v| function_name = v }
  parser.on("-r REGION", "--region REGION", "region for cloud function deployment, only us-central1 is valid") { |v| region = v }
  parser.on("-m MEMORY", "--memory MEMORY", "ram/memory allocated for cloud function, valid: 128 MB | 256 MB | 512 MB | 1 GB | 2 GB") { |v| function_memory = v }
  parser.on("-c VERSION", "--crystal VERSION", "version of crystal to use for this deployment e.g. \"0.24.2\"") { |v| crystal_version = v }
  parser.on("-t TRIGGER", "--trigger TRIGGER", "trigger mode for the cloud function, valid: http, topic, bucket-create, bucket-delete, bucket-archive, bucket-metadata-update") do |v|
    trigger_mode = v
  end
  parser.on("-T TOPIC", "--topic TOPIC", "trigger topic name when deploying a topic-triggered cloud function") { |v| topic = v }
  parser.on("-b BUCKET", "--bucket BUCKET", "trigger bucket name when deploying using a bucket-triggered cloud function") { |v| bucket = v }
  parser.on("-v", "--version", "prints the version") { print_version }
  options_parser = parser
end

# check prerequisites
require_app! "git"
require_app! "zip"
require_app! "unzip"
require_app! "gcloud"

# display usage info if no action to take
unless run_deploy
  print_version
  puts "note: you must specify --deploy in order to deploy"
  puts ""
  puts options_parser
  puts ""
  exit 0
end

print_version
puts "preparing for deployment..."

# check for valid region
if region != "us-central1"
  puts "error: the only valid cloud function region at the moment is \"us-central1\". You specified \"#{region}\""
  exit 1
end

# get project_id from gcloud if not already set
if project_id == ""
  project_id = gcloud_project_id
else
  puts " => set project ID to \"#{project_id}\""
end

# parse source_path
raise "source directory could not be found" unless File.exists?(source_path)
FileUtils.cd source_path
source_path = FileUtils.pwd
source_directory_name = File.basename(source_path)
puts " => source path set to \"#{source_path}\""

# parse function_name
function_name = source_directory_name if function_name == ""
puts " => function_name set to \"#{function_name}\""

# parse memory
unless POSSIBLE_MEMORY_CONFIGS.includes?(function_memory)
  raise "#{function_memory} is not a valid memory configuration. Must be one of #{POSSIBLE_MEMORY_CONFIGS}"
end
puts " => function memory set to #{function_memory}"

# parse version
unless valid_version? crystal_version
  raise "#{crystal_version} is not a valid crystal version, e.g. 0.24.2"
end
puts " => crystal version set to #{crystal_version}"

# parse trigger mode
orig_trigger_mode = trigger_mode
case trigger_mode
when "http"
  trigger_mode = :http
  http_trigger = "https://#{region}-#{project_id}.cloudfunctions.net/#{function_name}"
  puts " => trigger mode set to http on \"#{http_trigger}\""
when "topic"
  trigger_mode = :topic
  raise "must define a topic when using a topic-based trigger mode" if topic == ""
  puts " => trigger mode set to topic on topic \"#{topic}\""
when "bucket-create"; trigger_mode = :bucket_create
when "bucket-delete"; trigger_mode = :bucket_delete
when "bucket-archive"; trigger_mode = :bucket_archive
when "bucket-metadata-update"; trigger_mode = :bucket_metadata_update
else
  raise "trigger mode must be one of #{POSSIBLE_TRIGGER_MODES}"
end

# parse bucket
case trigger_mode
when :bucket_create, :bucket_delete, :bucket_archive, :bucket_metadata_update
  raise "must define a bucket name when using a bucket-based trigger mode" if bucket == ""
  puts " => trigger mode set to #{orig_trigger_mode} on bucket \"#{bucket}\""
end

# prepare staging directory
staging_dir = temp_dir("crystal-gcf-deploy", false)
unzip_dir = temp_dir("crystal-unzip-dir", true)
zip_contents =  FileStorage.get("compile-crystal.zip").gets_to_end
File.write("#{unzip_dir}/compile-crystal.zip", zip_contents)
FileUtils.cd unzip_dir
`unzip #{unzip_dir}/compile-crystal.zip`
FileUtils.cp_r "#{unzip_dir}/compile-crystal/", staging_dir
FileUtils.cd staging_dir
`ls`
FileUtils.rm_rf "#{staging_dir}/node_modules"
puts " => staging directory set to \"#{staging_dir}\""

# zip up deployment target
zip_dir(source_path, "#{staging_dir}/payload.zip")
puts ""

# deploy compilation function
puts "creating staging/compilation function..."
compile_deploy_resp = `gcloud beta functions deploy compile-crystal --source=. --entry-point=init --memory=2048MB --timeout=540 --trigger-http`
unless compile_deploy_resp.includes? "status: ACTIVE"
  puts ""
  puts "an error occurred deploying the intermediate compilation function"
  exit 1
end
puts "success."
