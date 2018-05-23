APPNAME = "gcf.cf"
APPBIN = "gcf"

require "./gcf/*"
require "option_parser"

def print_version
  puts ""
  puts "#{APPNAME} v#{GCF::VERSION}"
  puts ""
end

project_id = ""
source_path = "."
function_name = ""

OptionParser.parse! do |parser|
  parser.banner = "usage: #{APPBIN} [arguments]"
  parser.on("-h", "--help", "show this help") { puts ""; puts parser; puts "" }
  parser.on("-p", "--project", "sets the Google project ID for cloud functions, defaults to current gcloud project id") { |v| project_id = v }
  parser.on("-s", "--source", "path or git link to source code to be deployed, defaults to '.'") { |v| source_path = v }
  parser.on("-n", "--name", "cloud function name, defaults to name of directory or repo") { |v| function_name = v }
  parser.on("-v", "--version", "prints the version") { print_version }
end

require_app! "git"
require_app! "zip"
require_app! "unzip"
require_app! "gcloud"
