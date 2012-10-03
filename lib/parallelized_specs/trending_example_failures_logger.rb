require 'parallelized_specs/spec_logger_base'

class ParallelizedSpecs::TrendingExampleFailures < ParallelizedSpecs::SpecLoggerBase
  def initialize(*args)
    @output ||= args[1] || args[0] # rspec 1 has output as second argument
    @hudson_build_info = File.read("#{RAILS_ROOT}/spec/build_info.txt")
    if String === @output # a path ?
      FileUtils.mkdir_p(File.dirname(@output))
      @output = File.open(@output, 'a+')
    elsif File === @output # close and restart in append mode
      @output.close
      @output = File.open(@output.path, 'a+')
    end
  end

  def example_failed(example, counter, failure)
    if RSPEC_1
      if example.location != nil
      super
        @failed_examples ||= {}
        @failed_examples["#{example.location.match(/spec.*\d/).to_s}*"] = ["#{example.description}*", "#{failure.header}*", "#{failure.exception.to_s.gsub(/\n/,"")}*", "#{failure.exception.backtrace.to_s.gsub(/\n/,"")}*", "#{Time.now.to_date}*", "#{@hudson_build_info}"]
      end
    end
  end

  # RSpec 1: dumps 1 failed spec
  def dump_failure(*args)
  end

  # RSpec 2: dumps all failed specs
  def dump_failures(*args)
  end

  def dump_summary(*args)
    lock_output do
      (@failed_examples||{}).each_pair do |example, details|
        @output.puts "#{example}#{details}"
      end
      @output.flush
    end
  end
end

