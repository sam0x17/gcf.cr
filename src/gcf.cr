APPNAME = "gcf.cr"
APPBIN = "gcf"

require "./gcf/*"
require "option_parser"

def print_version
  puts ""
  puts "#{APPNAME} v#{GCF::VERSION}"
  puts ""
end

# initialize config info
project_id = ""
source_path = "."
function_name = ""
run_deploy = false

options_parser = nil

# read command line args
OptionParser.parse! do |parser|
  parser.banner = "usage: #{APPBIN} [arguments]"
  parser.on("-h", "--help", "show this help") { puts ""; puts parser; puts "" }
  parser.on("-d", "--deploy", "required to indicate that you intend to deploy") { run_deploy = true }
  parser.on("-p", "--project", "sets the Google project ID, defaults to current gcloud setting") { |v| project_id = v }
  parser.on("-s", "--source", "path or git link to source code to be deployed, defaults to '.'") { |v| source_path = v }
  parser.on("-n", "--name", "cloud function name, defaults to name of directory or repo") { |v| function_name = v }
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
