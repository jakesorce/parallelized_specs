require 'parallelized_specs/spec_logger_base'


module RSpec
  class ParallelizedSpecs::FailuresFormatter < ParallelizedSpecs::SpecLoggerBase
    FILENAME = "#{RAILS_ROOT}/tmp/parallel_log/rspec.failures"

    def example_failed(example, counter, failure)
      f = File.new(FILENAME, "a+")
      f.puts retry_command(example)
    end

    def dump_summary(*args)
    end

    def dump_failures(*args)
      ;
    end

    def dump_failure(*args)
      ;
    end

    def dump_pending(*args)
      ;
    end

    def retry_command(example)
      spec_file = example_group.location.gsub("\"", "\\\"").match(/spec.*b/).to_s
      spec_name = example.description
      "SPEC=#{Dir.pwd}/#{spec_file} SPEC_OPTS='-e \"#{spec_name}\"'"
    end
  end
end
