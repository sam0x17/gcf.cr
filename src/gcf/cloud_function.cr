class GCF::CloudFunction
  private class Console
    def warn(msg)
      @std_warn.puts msg + "\n"
      
    end

    def error(msg)
      @std_error.puts msg + "\n"
    end

    def log(msg)
      @std_info.puts msg + "\n"
    end

    def initialize
      File.delete("/tmp/.gcf_info_log") if File.exists?("/tmp/.gcf_info_log")
      File.delete("/tmp/.gcf_warn_log") if File.exists?("/tmp/.gcf_warn_log")
      File.delete("/tmp/.gcf_error_log") if File.exists?("/tmp/.gcf_error_log")
      @std_info = File.new "/tmp/.gcf_info_log", "w"
      @std_warn = File.new "/tmp/.gcf_warn_log", "w"
      @std_error = File.new "/tmp/.gcf_error_log", "w"
      @std_info.flush_on_newline = true
      @std_warn.flush_on_newline = true
      @std_error.flush_on_newline = true
      at_exit do
        File.delete("/tmp/.gcf_info_log") if File.exists?("/tmp/.gcf_info_log")
        File.delete("/tmp/.gcf_warn_log") if File.exists?("/tmp/.gcf_warn_log")
        File.delete("/tmp/.gcf_error_log") if File.exists?("/tmp/.gcf_error_log")
      end
    end
  end

  def initialize
    @console = Console.new
  end

  def puts(msg)
    console.log msg
  end

  def console
    @console
  end

  def run
  end
end
