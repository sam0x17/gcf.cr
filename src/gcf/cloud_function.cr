require "json"

abstract class GCF::CloudFunction
  private class Console
    def warn(msg)
      @std_warn.puts "#{msg}\n"
    end

    def error(msg)
      @std_error.puts "#{msg}\n"
    end

    def log(msg)
      @std_info.puts "#{msg}\n"
    end

    def initialize
      File.delete("/tmp/.gcf_info_log") if File.exists?("/tmp/.gcf_info_log")
      File.delete("/tmp/.gcf_warn_log") if File.exists?("/tmp/.gcf_warn_log")
      File.delete("/tmp/.gcf_error_log") if File.exists?("/tmp/.gcf_error_log")
      @std_info = File.new "/tmp/.gcf_info_log", "w"
      @std_warn = File.new "/tmp/.gcf_warn_log", "w"
      @std_error = File.new "/tmp/.gcf_error_log", "w"
      [@std_info, @std_warn, @std_error].each { |f| f.flush_on_newline = true }
      @std_info.flush_on_newline = true
      @std_warn.flush_on_newline = true
      @std_error.flush_on_newline = true
    end
  end

  def initialize
    File.delete("/tmp/.gcf_text_output") if File.exists?("/tmp/.gcf_text_output")
    File.delete("/tmp/.gcf_file_output") if File.exists?("/tmp/.gcf_file_output")
    File.delete("/tmp/.gcf_redirect_url") if File.exists?("/tmp/.gcf_redirect_url")
    File.delete("/tmp/.gcf_redirect_mode") if File.exists?("/tmp/.gcf_redirect_mode")
    File.delete("/tmp/.gcf_status") if File.exists?("/tmp/.gcf_status")
    @console = Console.new
    @text_output = File.new "/tmp/.gcf_text_output", "w"
    @file_output = File.new "/tmp/.gcf_file_output", "w"
    @redirect_url = File.new "/tmp/.gcf_redirect_url", "w"
    @redirect_mode = File.new "/tmp/.gcf_redirect_mode", "w"
    @status_code = File.new "/tmp/.gcf_status", "w"
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

  private def write_status(status : Int)
    @status_code.write status.to_s.to_slice
    @status_code.close
  end
end
