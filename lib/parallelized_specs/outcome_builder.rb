require 'parallelized_specs/spec_logger_base'

module RSpec

  class ParallelizedSpecs::OutcomeBuilder < ParallelizedSpecs::SpecLoggerBase

    def start(example_count)
      @example_count = example_count
      env_test_number = ENV['TEST_ENV_NUMBER']
      env_test_number = 1 if ENV['TEST_ENV_NUMBER'].blank?
      puts "Thread #{env_test_number.to_s} has #{@example_count} specs"
      File.open("tmp/parallel_log/spec_count/total_specs#{env_test_number}.txt", 'a+') { |f| f.write(@example_count) }
      super
    end


    def dump_summary(duration, example_count, failure_count, pending_count)
      env_test_number = ENV['TEST_ENV_NUMBER']
      env_test_number = 1 if ENV['TEST_ENV_NUMBER'].blank?
      spec_file = "tmp/parallel_log/spec_count/total_specs#{env_test_number}.txt"
      failure_file = "tmp/parallel_log/failed_specs/failed_specs#{env_test_number}.txt"
      before_example_count = File.open(spec_file, &:readline).to_s
      puts "Expected example count = #{before_example_count} from rspec example count = #{example_count}"
      File.delete(spec_file) if before_example_count.to_i == example_count.to_i
      puts "Thread example failure count = #{failure_count}"
      failure_count > 0 ? (File.open(failure_file, 'a+') { |f| f.write(failure_count) }) : (puts "All specs in Thread #{env_test_number} passed")
      puts "Thread #{env_test_number} has completed in #{duration}"
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
  end
end
