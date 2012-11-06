require 'parallelized_specs/spec_logger_base'


module RSpec
  class ParallelizedSpecs::FailuresFormatter < ParallelizedSpecs::SpecLoggerBase

    def example_failed(example, counter, failure)
      lock_output do
        @output.puts retry_command(example)
      end
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
