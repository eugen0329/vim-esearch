# frozen_string_literal: true

class DumpVimEnvironmentErrorFormatter
  attr_reader :out

  RSpec::Core::Formatters.register self, :example_failed

  def initialize(out)
    @out = out
  end

  def example_failed(_notification)
    out << colorize("             buffers: \n\t#{Debug.buffers.join("\n\t")}\n")
    out << colorize("      buffer_content: \n\t#{Debug.buffer_content.join("\n\t")}\n")
    out << colorize("            messages: \n\t#{Debug.messages&.join("\n\t")}\n")
    out << colorize(" working_directories: #{Debug.working_directories}\n")
    out << colorize("global_configuration: #{Debug.global_configuration}\n")
    out << colorize("buffer_configuration: \n\t#{Debug.buffer_configuration}\n")
    out << colorize("        runtimepaths: \n\t#{Debug.runtimepaths.join("\n\t")}\n")
    out << colorize("     sourced_scripts: \n\t#{Debug.sourced_scripts.join("\n\t")}\n")
    out << colorize("   user_autocommands: \n\t#{Debug.user_autocommands.join("\n\t")}\n")
    out << colorize("          plugin_log: \n\t#{Debug.plugin_log&.join("\n\t")}\n")
    out << colorize("            nvim_log: \n\t#{Debug.nvim_log&.join("\n\t")}\n")
    out << colorize("         verbose_log: \n\t#{Debug.verbose_log&.join("\n\t")}\n")
    out << colorize("         update_time: #{Debug.update_time}\n")
    # out <colorizer.wrap(< Debug.screenshot!
  end

  def colorize(string)
    RSpec::Core::Formatters::ConsoleCodes.wrap(string, color)
  end

  def color
    RSpec.configuration.detail_color
  end
end
