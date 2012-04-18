require 'parallelized_specs'
require File.join(File.dirname(__FILE__), 'spec_logger_base')

class ParallelizedSpecs::SpecStartFinishLogger < ParallelizedSpecs::SpecLoggerBase
  def initialize(options, output=nil)
    output ||= options # rspec 2 has output as first argument

    output = "#{output}_#{ENV['TEST_ENV_NUMBER']}.log"
    if String === output
      FileUtils.mkdir_p(File.dirname(output))
      File.open(output, 'w'){} # overwrite previous results
      @output = File.open(output, 'a')
    elsif File === output
      output.close # close file opened with 'w'
      @output = File.open(output.path, 'a')
    else
      @output = output
    end
  end

  def example_started(example)
    @output.puts ""
    @output.puts "started spec: #{example.description}"
  end

  def example_passed(example)
    @output.puts "finished spec: #{example.description}"
  end

  def example_pending(example, message)
    @output.puts "finished spec: #{example.description}"
  end

  def example_failed(example, count, failure)
    @output.puts "finished spec: #{example.description}"
  end

end
