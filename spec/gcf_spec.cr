require "./spec_helper"

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
    GCF.http_trigger.should eq "https://us-central1-test-project.cloudfunctions.net/gcf.cr"
  end
end
