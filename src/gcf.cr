require "./gcf/*"
require "option_parser"
require "file_utils"
require "http/client"

module GCF
  APPNAME = "gcf.cr"
  APPBIN = "gcf"
  POSSIBLE_MEMORY_CONFIGS = ["128MB", "256MB", "512MB", "1GB", "2GB"]
  POSSIBLE_TRIGGER_MODES = ["http", "topic", "bucket-create", "bucket-delete", "bucket-archive", "bucket-metadata-update"]
  PWD = `pwd`.strip
  CRYSTAL_STATIC_BUILD = "crystal build src/*.cr -o crystal_function --release --static --no-debug"

  run_gcf if ::PROGRAM_NAME.ends_with? APPBIN

  def self.print_version
    puts ""
    puts "#{APPNAME} v#{GCF::VERSION}"
    puts ""
  end

  def self.run_gcf
    # initialize config info
    project_id = ""
    source_path = "."
    function_name = ""
    http_trigger = ""
    region = "us-central1"
    function_memory = "128MB"
    trigger_mode = "http"
    bucket = ""
    topic = ""

    run_deploy = false
    use_local_crystal = false

    options_parser = nil

    # read command line args
    OptionParser.parse! do |parser|
      parser.banner = "usage: #{APPBIN} [arguments]"
      parser.on("-h", "--help", "show this help") { puts ""; puts parser; puts "" }
      parser.on("-d", "--deploy", "required to indicate that you intend to deploy") { run_deploy = true }
      parser.on("-l", "--local", "attempt to statically compile crystal function using local system crystal") { use_local_crystal = true }
      parser.on("-p PROJECT", "--project PROJECT", "Google project ID, defaults to current gcloud setting") { |v| project_id = v }
      parser.on("-s PATH", "--source PATH", "path to source code to be deployed, defaults to '.'") { |v| source_path = v }
      parser.on("-n NAME", "--name NAME", "cloud function name, defaults to name of directory or repo") { |v| function_name = v }
      parser.on("-r REGION", "--region REGION", "region for cloud function deployment, only us-central1 is valid") { |v| region = v }
      parser.on("-m MEMORY", "--memory MEMORY", "ram/memory allocated for cloud function, valid: 128MB | 256MB | 512MB | 1GB | 2GB") { |v| function_memory = v }
      parser.on("-t TRIGGER", "--trigger TRIGGER", "trigger mode for the cloud function, valid: http, topic, bucket-create, bucket-delete, bucket-archive, bucket-metadata-update") do |v|
        trigger_mode = v
      end
      parser.on("-T TOPIC", "--topic TOPIC", "trigger topic name when deploying a topic-triggered cloud function") { |v| topic = v }
      parser.on("-b BUCKET", "--bucket BUCKET", "trigger bucket name when deploying using a bucket-triggered cloud function") { |v| bucket = v }
      parser.on("-v", "--version", "prints the version") { print_version }
      options_parser = parser
    end

    # check prerequisites
    require_app! "gcloud"
    require_app! "docker"
    if !docker_available? && !use_local_crystal
      puts "error: docker must be set up to work without sudo privileges unless using the --local option. Please see the following guide for more information:"
      puts "https://docs.docker.com/install/linux/linux-postinstall/#manage-docker-as-a-non-root-user"
      exit 1
    else
      # crystal is required only if we aren't using docker to generate our crystal binary
      require_app! "crystal"
    end

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
      polite_raise! "#{function_memory} is not a valid memory configuration. Must be one of #{POSSIBLE_MEMORY_CONFIGS}"
    end
    puts " => function memory set to #{function_memory}"

    # parse trigger mode
    orig_trigger_mode = trigger_mode
    case trigger_mode
    when "http"
      trigger_mode = :http
      http_trigger = "https://#{region}-#{project_id}.cloudfunctions.net/#{function_name}"
      puts " => trigger mode set to http on \"#{http_trigger}\""
    when "topic"
      trigger_mode = :topic
      polite_raise! "must define a topic when using a topic-based trigger mode" if topic == ""
      puts " => trigger mode set to topic on topic \"#{topic}\""
    when "bucket-create"; trigger_mode = :bucket_create
    when "bucket-delete"; trigger_mode = :bucket_delete
    when "bucket-archive"; trigger_mode = :bucket_archive
    when "bucket-metadata-update"; trigger_mode = :bucket_metadata_update
    else
      polite_raise! "trigger mode must be one of #{POSSIBLE_TRIGGER_MODES}"
    end

    # parse bucket
    case trigger_mode
    when :bucket_create, :bucket_delete, :bucket_archive, :bucket_metadata_update
      polite_raise! "must define a bucket name when using a bucket-based trigger mode" if bucket == ""
      puts " => trigger mode set to #{orig_trigger_mode} on bucket \"#{bucket}\""
    end

    unless trigger_mode == :http
      polite_raise! "non http trigger modes are not yet supported"
    end

    # prepare staging directory
    staging_dir = temp_dir("crystal-gcf-deploy", false)
    FileUtils.cp_r "#{source_path}/", staging_dir
    if File.exists? "#{staging_dir}/crystal.js"
      polite_raise! "you cannot have a file named crystal.js in your source directory"
    end
    if File.exists? "#{staging_dir}/package.json"
      polite_raise! "you cannot have a file named package.json in your source directory"
    end
    File.write("#{staging_dir}/package.json", GCF::DeployTemplate::PACKAGE_INFO)
    File.write("#{staging_dir}/crystal.js", GCF::DeployTemplate::CRYSTAL_JS)
    FileUtils.rm_rf_if_exists "#{staging_dir}/node_modules"
    FileUtils.cd staging_dir
    puts " => staging directory set to \"#{staging_dir}\""
    puts ""

    # compile crystal function
    if use_local_crystal
      puts "compiling static binary using local crystal installation: #{`crystal --version`.strip}..."
      comp_result = `#{CRYSTAL_STATIC_BUILD}`
    else
      puts "compiling static binary using the jrei/crystal-alpine docker image..."
      comp_result = `docker run --rm -it -v $PWD:/app -w /app jrei/crystal-alpine #{CRYSTAL_STATIC_BUILD}`
    end
    polite_raise! comp_result if comp_result.includes? "error"
    polite_raise! "project did not compile successfully" unless File.exists? "crystal_function"
    puts "compilation done."
    puts ""

    puts "deploying #{function_name} via gcloud..."
    deploy_resp = `gcloud beta functions deploy #{function_name} --source=. --entry-point=init --memory=#{function_memory} --timeout=540 --trigger-http`
    unless deploy_resp.includes? "status: ACTIVE"
      polite_raise! "an error occurred deploying #{function_name}:\n#{deploy_resp}"
    end
  end
end
