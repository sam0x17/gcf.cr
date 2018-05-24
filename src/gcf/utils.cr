GCLOUD_INSTALLED = `which gcloud` != ""
GIT_INSTALLED = `which git` != ""
UNZIP_INSTALLED = `which unzip` != ""
ZIP_INSTALLED = `which zip` != ""

def app_installed?(bin)
  `which #{bin}` != ""
end

def require_app!(bin)
  raise "#{bin} must be installed to use #{APPNAME}" unless app_installed?(bin)
end

def gcloud_project_id
  `gcloud config get-value project`
end

def zip_directory(dir_path, zip_file_path)
  `zip -r "#{zip_file_path}" "#{dir_path}"`
end
