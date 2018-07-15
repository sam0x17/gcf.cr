require "json"

module GCF
  protected def self.cf_puts(category : String, data)
    if GCF.test_mode
      GCF.cflog += "#{category}: #{data.to_s}\n"
    else
      puts "#{category}: #{data.to_s}"
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
  end

  def initialize
    File.delete("/tmp/.gcf_text_output") if File.exists?("/tmp/.gcf_text_output")
    File.delete("/tmp/.gcf_file_output") if File.exists?("/tmp/.gcf_file_output")
    File.delete("/tmp/.gcf_redirect_url") if File.exists?("/tmp/.gcf_redirect_url")
    File.delete("/tmp/.gcf_redirect_mode") if File.exists?("/tmp/.gcf_redirect_mode")
    File.delete("/tmp/.gcf_status") if File.exists?("/tmp/.gcf_status")
    File.delete("/tmp/.gcf_exception") if File.exists?("/tmp/.gcf_exception")
    @console = Console.new
    @text_output = File.new "/tmp/.gcf_text_output", "w"
    @file_output = File.new "/tmp/.gcf_file_output", "w"
    @redirect_url = File.new "/tmp/.gcf_redirect_url", "w"
    @redirect_mode = File.new "/tmp/.gcf_redirect_mode", "w"
    @status_code = File.new "/tmp/.gcf_status", "w"
    @exception = File.new "/tmp/.gcf_exception", "w"
  end

  macro inherited
    exec unless GCF.test_mode
  end

  def self.exec
    cf = self.new
    begin
      cf.run
    rescue ex
      cf.raise_exception ex
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
    exit 0 unless GCF.test_mode
  end

  def send_file(status : Int, path : String)
    no_text_output
    no_redirect_output
    write_status status
    @file_output.puts path
    @file_output.close
    exit 0 unless GCF.test_mode
  end

  def redirect(url : String)
    redirect false, url
  end

  def redirect(permanent : Bool, url : String)
    no_text_output
    no_file_output
    @redirect_url.write url.to_s.to_slice
    @redirect_url.close
    @redirect_mode.write (permanent ? 301 : 302).to_s.to_slice
    @redirect_mode.close
    exit 0 unless GCF.test_mode
  end

  abstract def run(params : JSON::Any = JSON.parse(""))

  private def no_file_output
    @file_output.close
    File.delete @file_output.path
  end

  private def no_text_output
    @text_output.close
    File.delete @text_output.path
  end

  private def no_redirect_output
    @redirect_url.close
    File.delete @redirect_url.path
    @redirect_mode.close
    File.delete @redirect_mode.path
  end

  protected def raise_exception(ex : Exception)
    ex.inspect_with_backtrace(@exception)
    @exception.close
    no_text_output
    no_file_output
    write_status 500
    exit 1 unless GCF.test_mode
  end

  private def write_status(status : Int)
    @status_code.write status.to_s.to_slice
    @status_code.close
  end
end
