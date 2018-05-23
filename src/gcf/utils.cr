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
