require "./spec_helper"

class TestCloudFunction < GCF::CloudFunction
  def run
  end
end

class TestLogFunction < GCF::CloudFunction
  def run
    console.log "info test 1"
    console.log "info test 2"
    console.warn "warn test 1"
    console.warn "warn test 2"
    console.error "error test 1"
    console.error "error test 2"
  end
end

class ErrorCloudFunction < GCF::CloudFunction
  def run
    console.log "doing some stuff"
    raise "OH MY GOD, THEY KILLED KENNY!"
  end
end

describe GCF do
  describe "integration" do
    it "writes to logs correctly" do
      TestLogFunction.exec
      GCF.cflog.should eq "gcf-info: info test 1\ngcf-info: info test 2\ngcf-warn: warn test 1\ngcf-warn: warn test 2\ngcf-error: error test 1\ngcf-error: error test 2\n"
    end

    it "writes info log correctly" do
      cf = TestCloudFunction.new
      cf.console.log "whats up"
      GCF.cflog.should eq "gcf-info: whats up\n"
    end

    it "writes warn log correctly" do
      cf = TestCloudFunction.new
      cf.console.warn "whats up"
      GCF.cflog.should eq "gcf-warn: whats up\n"
    end

    it "writes error log correctly" do
      cf = TestCloudFunction.new
      cf.console.error "whats up"
      GCF.cflog.should eq "gcf-error: whats up\n"
    end

    it "writes multiline things to log correctly" do
      cf = TestCloudFunction.new
      cf.console.log "hey\nmulti\nlines"
      GCF.cflog.should eq "gcf-info: hey\ngcf-info: multi\ngcf-info: lines\n"
    end

    it "handles exceptions correctly" do
      ErrorCloudFunction.exec
      GCF.cflog.includes?("OH MY GOD, THEY KILLED KENNY! (Exception)").should eq true
      GCF.cflog.includes?("from spec/gcf_spec.cr").should eq true
      File.read("/tmp/.gcf_status").should eq "500"
    end

    it "sends status correctly for text" do
      cf = TestCloudFunction.new
      cf.send("test")
      File.read("/tmp/.gcf_status").should eq "200"
    end

    it "sends status correctly for files" do
      cf = TestCloudFunction.new
      cf.send_file(300, "test")
      File.read("/tmp/.gcf_status").should eq "300"
    end

    it "redirects correctly" do
      cf = TestCloudFunction.new
      cf.redirect("http://www.google.com")
      File.read("/tmp/.gcf_redirect_url").should eq "http://www.google.com"
      File.read("/tmp/.gcf_status").should eq "302"
    end

    it "perma redirects correctly" do
      cf = TestCloudFunction.new
      cf.redirect(true, "http://www.google.com")
      File.read("/tmp/.gcf_redirect_url").should eq "http://www.google.com"
      File.read("/tmp/.gcf_status").should eq "301"
    end
  end

  it "checks for prerequisites" do
    GCF.check_prerequisites
  end

  it "sets all properties correctly before deployment" do
    GCF.project_id.should eq GCF::DEFAULT_PROJECT_ID
    GCF.source_path.should eq GCF::DEFAULT_SOURCE_PATH
    GCF.function_name.should eq GCF::DEFAULT_FUNCTION_NAME
    GCF.http_trigger.should eq GCF::DEFAULT_HTTP_TRIGGER
    GCF.region.should eq GCF::DEFAULT_REGION
    GCF.function_memory.should eq GCF::DEFAULT_FUNCTION_MEMORY
    GCF.trigger_mode.should eq GCF::DEFAULT_TRIGGER_MODE
    GCF.bucket.should eq GCF::DEFAULT_BUCKET
    GCF.topic.should eq GCF::DEFAULT_TOPIC
    GCF.staging_dir.should eq GCF::DEFAULT_STAGING_DIR
    GCF.run_deploy.should eq GCF::DEFAULT_RUN_DEPLOY
    GCF.use_local_crystal.should eq true
    GCF.silent_mode.should eq true
    GCF.test_mode.should eq true
  end

  it "does nothing if --deploy is not specified" do
    GCF.deploy_ran.should eq false
    GCF.run
    GCF.deploy_ran.should eq false
  end

  # it "deploys correctly if --deploy is specified" do
  #   GCF.project_id = "test-project"
  #   GCF.deploy_ran.should eq false
  #   GCF.run_deploy = true
  #   GCF.run
  #   GCF.deploy_ran.should eq true
  # end

  # it "deploys http_trigger functions correctly" do
  #   GCF.trigger_mode = "http"
  #   GCF.http_trigger.should eq GCF::DEFAULT_HTTP_TRIGGER
  #   GCF.project_id = "test-project"
  #   GCF.run_deploy = true
  #   GCF.run
  #   GCF.deploy_ran.should eq true
  #   GCF.http_trigger.should_not eq GCF::DEFAULT_HTTP_TRIGGER
  #   GCF.http_trigger.should eq "https://us-central1-test-project.cloudfunctions.net/#{File.basename GCF::PWD}"
  # end
end
