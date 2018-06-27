def puts_safe(message)
  return if GCF.silent_mode
  puts message
end

module GCF
  def self.polite_raise!(message)
    puts ""
    puts "error: #{message}"
    puts ""
    raise message if test_mode
    exit 1
  end

  @@static_comp_available = nil
  def self.static_compilation_available?
    return @@static_comp_available if @@static_comp_available != nil
    pwd = `pwd`.strip
    dir = temp_dir "compile-test"
    FileUtils.cd dir
    File.write(dir + "/test.cr", "exit 0")
    res = `crystal build test.cr --static --no-debug 2>&1`
    FileUtils.cd pwd
    @@static_comp_available = !res.downcase.includes? "error"
  end

  def self.app_installed?(bin)
    `which #{bin}` != ""
  end

  def self.require_app!(bin)
    return if app_installed?(bin) || test_mode
    polite_raise! "#{bin} must be installed to use #{APPNAME}"
  end

  def self.docker_available?
    return true if test_mode
    output = `docker info`
    !(output.includes?("denied") || output.includes?("Cannot connect to the Docker daemon"))
  end

  def self.gcloud_project_id
    return "test-project" if test_mode
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
    dir = "/tmp/#{prefix}-#{Time.now.epoch}-#{random_string(6)}"
    FileUtils.mkdir_p dir
    FileUtils.rm_rf dir # delete if existed before
    FileUtils.mkdir_p(dir) if create
    at_exit { FileUtils.rm_rf(dir) if File.exists?(dir) }
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
