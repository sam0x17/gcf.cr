{% unless flag?(:production) %}

require "kemal"

module GCF::TestServer
  def self.run(klass)
    get "/" do |env|
      cloud_function = klass.new
      params = env.params.body.to_h.merge(env.params.url.to_h).merge(env.params.query.to_h)
      cloud_function.run JSON.parse(params.to_json)
      if File.exists?("/tmp/.gcf_text_output")
        File.read("/tmp/.gcf_text_output")
      elsif File.exists?("/tmp/.gcf_file_output")
        send_file env, "/tmp/.gcf_file_output"
      elsif File.exists?("/tmp/.gcf_redirect_url")
        env.redirect File.read("/tmp/.gcf_redirect_url"), File.read("/tmp/.gcf_status").to_i
      else
        raise "page did not send or redirect anything"
      end
    end
    Kemal.config.port = 8080
    Kemal.run
  end
end

{% end %}
