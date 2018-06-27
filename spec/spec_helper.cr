require "spec"
require "../src/gcf"

Spec.before_each do
  GCF.reset_config
  GCF.test_mode = true
  GCF.silent_mode = true
  GCF.use_local_crystal = true
  sleep 0.01
end
