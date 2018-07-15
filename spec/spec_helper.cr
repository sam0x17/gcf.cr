require "spec"
require "../src/gcf"
GCF.test_mode = true

Spec.before_each do
  GCF.reset_config
  GCF.test_mode = true
  GCF.silent_mode = true
  GCF.use_local_crystal = true
  FileUtils.cd GCF::PWD
end
