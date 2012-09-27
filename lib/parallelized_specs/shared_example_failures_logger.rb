require 'parallelized_specs/spec_logger_base'

class ParallelizedSpecs::SharedExampleRerunFailuresLogger < ParallelizedSpecs::SpecLoggerBase

  def example_failed(example, *args)
    if RSPEC_1
      @failed_shared_examples ||= {}
      spec_caller = self.example_group.backtrace.match(/spec.*\d/).to_s #regex later to get right relative path
      failed_shared_spec = example.location.match(/spec.*\d/).to_s

      if !!self.example_group.nested_descriptions.to_s.match(/shared/) || !!self.instance_variable_get(:@example_group).examples.last.location.match(/helper/)
        if spec_caller == @failed_shared_examples.keys.last || spec_caller == @failed_shared_examples.keys.first || !!spec_caller.match(/helper/)
          key = @failed_shared_examples.keys.first
          @failed_shared_examples[key] << "#{failed_shared_spec} "
        else
          @failed_shared_examples["#{spec_caller}"] = ["#{failed_shared_spec} "]
        end
      end
    else
      super
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
      if RSPEC_1
        (@failed_shared_examples||{}).each_pair do |caller, example|
          @output.puts "#{caller}:\n\n #{example}\n\n "
        end
      end
      @output.flush
    end
  end

end
