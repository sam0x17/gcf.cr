require "json"

{% unless flag?(:production) %}
require "./test_server/test_server"
{% end %}

module GCF
  protected def self.cf_puts(category : String, data)
    data = "#{data}"
    data = data.gsub("\n", "\ngcf-#{category}: ")
    if GCF.test_mode
      GCF.cflog += "gcf-#{category}: #{data}\n"
    elsif GCF.production_mode?
      puts "gcf-#{category}: #{data}"
    else
      puts data
    end
  end
end

abstract class GCF::CloudFunction

  private class Console
    def warn(msg)
      GCF.cf_puts "warn", "#{msg}"
    end

    def error(msg)
      GCF.cf_puts "error", "#{msg}"
    end

    def log(msg)
      GCF.cf_puts "info", "#{msg}"
    end

    def exception(msg)
      GCF.cf_puts "exception", "#{msg}"
    end
  end

  def initialize
    File.delete("/tmp/.gcf_text_output") if File.exists?("/tmp/.gcf_text_output")
    File.delete("/tmp/.gcf_file_output") if File.exists?("/tmp/.gcf_file_output")
    File.delete("/tmp/.gcf_redirect_url") if File.exists?("/tmp/.gcf_redirect_url")
    File.delete("/tmp/.gcf_status") if File.exists?("/tmp/.gcf_status")
    @console = Console.new
    @text_output = File.new "/tmp/.gcf_text_output", "w"
    @file_output = File.new "/tmp/.gcf_file_output", "w"
    @redirect_url = File.new "/tmp/.gcf_redirect_url", "w"
    @status_code = File.new "/tmp/.gcf_status", "w"
  end

  macro inherited
    exec unless GCF.test_mode
  end

  def self.exec
    if GCF.production_mode? || GCF.test_mode
      params = JSON.parse "{}"
      if File.exists?("/tmp/.gcf_params")
        params = JSON.parse File.read("/tmp/.gcf_params")
        at_exit { File.delete("/tmp/.gcf_params") }
      end
      cf = self.new
      #begin
      cf.run params
      #rescue ex
      #  sb = String::Builder.new
      #  ex.inspect_with_backtrace(sb)
      #  cf.console.log sb.to_s
      #  cf.write_status 500
      #  exit 1 unless GCF.test_mode
      #end
    else
      {% unless flag?(:production) %}
      TestServer.run self
      {% end %}
    end
  end

  def puts(msg)
    console.log msg
  end

  def console
    @console
  end

  def send(text)
    send 200, text
  end

  def send_file(data)
    send_file 200, data
  end

  def send(status : Int, text)
    no_file_output
    no_redirect_output
    @text_output.puts text
    @text_output.close
    write_status status
    exit 0 unless GCF.test_mode || !GCF.production_mode?
  end

  def send_file(status : Int, path : String)
    no_text_output
    no_redirect_output
    write_status status
    @file_output.puts path
    @file_output.close
    exit 0 unless GCF.test_mode || !GCF.production_mode?
  end

  def redirect(url : String)
    redirect false, url
  end

  def redirect(permanent : Bool, url : String)
    no_text_output
    no_file_output
    @redirect_url.write url.to_s.to_slice
    @redirect_url.close
    write_status (permanent ? 301 : 302)
    exit 0 unless GCF.test_mode || !GCF.production_mode?
  end

  abstract def run(params : JSON::Any = JSON.parse("{}"))

  private def no_file_output
    @file_output.close
    File.delete @file_output.path if File.exists? @file_output.path
  end

  private def no_text_output
    @text_output.close
    File.delete @text_output.path if File.exists? @text_output.path
  end

  private def no_redirect_output
    @redirect_url.close
    File.delete @redirect_url.path if File.exists? @redirect_url.path
  end

  protected def write_status(status : Int)
    @status_code.write status.to_s.to_slice
    @status_code.close
  end
end
