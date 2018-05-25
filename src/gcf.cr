APPNAME = "gcf.cr"
APPBIN = "gcf"
POSSIBLE_MEMORY_CONFIGS = ["128 MB", "256 MB", "512 MB", "1 GB", "2 GB"]

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
  parser.on("-m MEMORY", "--memory MEMORY", "ram for cloud function, valid: 128 MB | 256 MB | 512 MB | 1 GB | 2 GB") { |v| function_memory = v }
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

# get project_id if not already set
project_id = gcloud_project_id if project_id == ""

# massage source_path
raise "source directory could not be found" unless File.exists?(source_path)
FileUtils.cd source_path
source_path = FileUtils.pwd
source_directory_name = File.basename(source_path)
puts " => source path set to \"#{source_path}\""

# massage function_name
function_name = source_directory_name if function_name == ""
puts " => function_name set to \"#{function_name}\""

# massage http_trigger
http_trigger = "https://#{region}-#{project_id}.cloudfunctions.net/#{function_name}"
puts " => http_trigger set to \"#{http_trigger}\""

# massage memory
unless POSSIBLE_MEMORY_CONFIGS.includes?(function_memory)
  raise "#{function_memory} is not a valid memory configuration. Must be one of #{POSSIBLE_MEMORY_CONFIGS}"
end
puts " => function_memory set to #{function_memory}"
