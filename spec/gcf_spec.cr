require "./spec_helper"

class TestCloudFunction < GCF::CloudFunction
  def run
    console.log "info test 1"
    console.log "info test 2"
    console.warn "warn test 1"
    console.warn "warn test 2"
    console.error "error test 1"
    console.error "error test 2"
  end
end

describe GCF do
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

  it "deploys correctly if --deploy is specified" do
    GCF.project_id = "test-project"
    GCF.deploy_ran.should eq false
    GCF.run_deploy = true
    GCF.run
    GCF.deploy_ran.should eq true
  end

  it "deploys http_trigger functions correctly" do
    GCF.trigger_mode = "http"
    GCF.http_trigger.should eq GCF::DEFAULT_HTTP_TRIGGER
    GCF.project_id = "test-project"
    GCF.run_deploy = true
    GCF.run
    GCF.deploy_ran.should eq true
    GCF.http_trigger.should_not eq GCF::DEFAULT_HTTP_TRIGGER
    GCF.http_trigger.should eq "https://us-central1-test-project.cloudfunctions.net/#{File.basename GCF::PWD}"
  end

  describe "integration" do
    it "writes to info log correctly" do
      cf = TestCloudFunction.new
      cf.run
      File.read("/tmp/.gcf_info_log").should eq "info test 1\ninfo test 2\n"
    end

    it "writes to warn log correctly" do
      cf = TestCloudFunction.new
      cf.run
      File.read("/tmp/.gcf_warn_log").should eq "warn test 1\nwarn test 2\n"
    end

    it "writes to error log correctly" do
      cf = TestCloudFunction.new
      cf.run
      File.read("/tmp/.gcf_error_log").should eq "error test 1\nerror test 2\n"
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
      File.read("/tmp/.gcf_redirect_output").should eq "http://www.google.com"
    end
  end
end
