require 'parallelized_specs/spec_logger_base'


module RSpec
  class ParallelizedSpecs::FailuresFormatter < ParallelizedSpecs::SpecLoggerBase
    #env_test_number = ENV['TEST_ENV_NUMBER']
    #env_test_number = 1 if ENV['TEST_ENV_NUMBER'].nil
    FILENAME = "#{RAILS_ROOT}/rspec.failures"

    def example_failed(example, counter, failure)
      @rerun_examples ||= []
      @rerun_examples << failure
      f = File.new(FILENAME, "a+")
      f.puts retry_command(example)
    end

    def dump_summary(*args)
      ;
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

    def close()
      rerun_failed_examples = false
      @rerun_failures ||= []
      @rerun_passes ||= []
      @error_count = %x{wc -l "#{RAILS_ROOT}/#{FILENAME}"}.match(/\d/).to_s #counts the number of lines in the file

      File.open("#{RAILS_ROOT}/#{FILENAME}").each_line do |l|
        if @error_count.to_i > 1 && 10 # if there is 1 line but less that 10 errors the rerun will run
          rerun_failed_examples = true
          result = %x[bundle exec rake spec #{l}]
          rerun_status = result.match(/FAILED/).to_s

          if rerun_status == "FAILED"
            @rerun_failures << l
            rerun_status = ""
          else
            @rerun_passes << l
            rerun_status = ""
          end
        end
      end #end file loop

      if rerun_failed_examples
        if @rerun_failures.length > 0
          puts "1 or more examples failed on rerun, rspec will mark this build as a failure"
        else
          puts "all rerun examples passed, rspec will mark this build as passed"
          $rerun_success = true
          Spec::Runner.options.instance_variable_get(:@reporter).instance_variable_get(:@failures).delete_if { |item| item != 'b' } #placeholder delete all failures in array approach
        end
      else
      end
      @output.close if (IO === @output) & (@output != $stdout)
    end
  end
end
