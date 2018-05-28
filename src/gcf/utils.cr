def app_installed?(bin)
  `which #{bin}` != ""
end

def require_app!(bin)
  raise "#{bin} must be installed to use #{APPNAME}" unless app_installed?(bin)
end

def gcloud_project_id
  project_id = `gcloud config get-value project`.strip
  puts " => obtained project ID \"#{project_id}\" from gcloud"
  project_id
end

def zip_dir(dir_path, zip_file_path)
  `zip -r "#{zip_file_path}" "#{dir_path}"`
  puts " => zipped #{dir_path} for deployment"
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
