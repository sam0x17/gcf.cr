def puts_safe(message)
  return if GCF.silent_mode
  puts message
end

module GCF
  def self.polite_raise!(message)
    puts ""
    puts "error: #{message}"
    puts ""
    exit 1
  end

  def self.app_installed?(bin)
    `which #{bin}` != ""
  end

  def self.require_app!(bin)
    return if app_installed? bin
    polite_raise! "#{bin} must be installed to use #{APPNAME}"
  end

  def self.docker_available?
    output = `docker info`
    !(output.includes?("denied") || output.includes?("Cannot connect to the Docker daemon"))
  end

  def self.gcloud_project_id
    project_id = `gcloud config get-value project`.strip
    puts_safe " => obtained project ID \"#{project_id}\" from gcloud"
    project_id
  end

  def self.random_alpha_numeric
    "abcdefghijklmnopqrstuvwxyz0123456789".chars.sample
  end

  def self.random_string(length)
    st = ""
    length.times { st += random_alpha_numeric }
    st
  end

  def self.temp_dir(prefix, create = true)
    dir = "/tmp/#{prefix}-#{Time.now.epoch}"
    FileUtils.mkdir_p dir
    FileUtils.rm_rf dir # delete if existed before
    FileUtils.mkdir_p(dir) if create
    at_exit { FileUtils.rm_rf dir }
    dir
  end

  def self.valid_version?(version)
    !!(/^v?[0-9]+.[0-9]+.[0-9]+$/ =~ version)
  end
end

module FileUtils
  def self.rm_rf_if_exists(path)
    FileUtils.rm_rf(path) if File.exists?(path)
  end
end
