def polite_raise!(message)
  puts ""
  puts "error: #{message}"
  puts ""
  exit 1
end

def app_installed?(bin)
  `which #{bin}` != ""
end

def require_app!(bin)
  return if app_installed? bin
  polite_raise! "#{bin} must be installed to use #{APPNAME}"
end

def docker_available?
  !`docker info`.includes? "denied"
end

def gcloud_project_id
  project_id = `gcloud config get-value project`.strip
  puts " => obtained project ID \"#{project_id}\" from gcloud"
  project_id
end

def random_alpha_numeric
  "abcdefghijklmnopqrstuvwxyz0123456789".chars.sample
end

def random_string(length)
  st = ""
  length.times { st += random_alpha_numeric }
  st
end

def temp_dir(prefix, create = true)
  dir = "/tmp/#{prefix}-#{Time.now.epoch}"
  FileUtils.mkdir_p dir
  FileUtils.rm_rf dir # delete if existed before
  FileUtils.mkdir_p(dir) if create
  at_exit { FileUtils.rm_rf dir }
  dir
end

def valid_version?(version)
  !!(/^v?[0-9]+.[0-9]+.[0-9]+$/ =~ version)
end

module FileUtils
  def self.rm_rf_if_exists(path)
    FileUtils.rm_rf(path) if File.exists?(path)
  end
end
