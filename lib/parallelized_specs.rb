require 'parallel'
raise "please ' gem install parallel '" if Gem::Version.new(Parallel::VERSION) < Gem::Version.new('0.4.2')
require 'optparse'
require 'parallelized_specs/grouper'
require 'parallelized_specs/railtie'
require 'parallelized_specs/spec_error_logger'
require 'parallelized_specs/spec_error_count_logger'
require 'parallelized_specs/spec_start_finish_logger'

class ParallelizedSpecs
  VERSION = File.read(File.join(File.dirname(__FILE__), '..', 'VERSION')).strip

  def self.run_tests(test_files, process_number, options)
    exe = executable # expensive, so we cache
    version = (exe =~ /\brspec\b/ ? 2 : 1)
    cmd = "#{rspec_1_color if version == 1}#{exe} #{options[:test_options]} #{rspec_2_color if version == 2}#{spec_opts(version)} #{test_files*' '}"
    execute_command(cmd, process_number, options)
  end

  def self.executable
    cmd = if File.file?("script/spec")
            "script/spec"
          elsif bundler_enabled?
            cmd = (run("bundle show rspec") =~ %r{/rspec-1[^/]+$} ? "spec" : "rspec")
            "bundle exec #{cmd}"
          else
            %w[spec rspec].detect { |cmd| system "#{cmd} --version > /dev/null 2>&1" }
          end
    cmd or raise("Can't find executables rspec or spec")
  end

  protected
  #so it can be stubbed....
  def self.run(cmd)
    `#{cmd}`
  end

  def self.rspec_1_color
    'RSPEC_COLOR=1 ; export RSPEC_COLOR ;' if $stdout.tty?
  end

  def self.rspec_2_color
    '--color --tty ' if $stdout.tty?
  end

  def self.spec_opts(rspec_version)
    options_file = %w(spec/parallelized_spec.opts spec/spec.opts).detect { |f| File.file?(f) }
    return unless options_file
    "-O #{options_file}"
  end

  def self.test_suffix
    "_spec.rb"
  end

  def self.execute_parallel_db(cmd, options={})
    count = options[:count].to_i
    count = Parallel.processor_count if count == 0
    runs = (0...count).to_a
    results = if options[:non_parallel]
                runs.map do |i|
                  execute_command(cmd, i, options)
                end
              else
                Parallel.map(runs, :in_processes => count) do |i|
                  execute_command(cmd, i, options)
                end
              end.flatten
    abort if results.any? { |r| r[:exit_status] != 0 }
  end

  def self.execute_parallel_specs(options)
    num_processes = options[:count] || Parallel.processor_count
    lib, name, task = {
        'spec' => %w(specs spec spec),
    }[options[:type]||'spec']

    start = Time.now

    tests_folder = task
    tests_folder = File.join(options[:root], tests_folder) unless options[:root].to_s.empty?
    if options[:files].is_a?(Array)
      groups = tests_in_groups(options[:files] || tests_folder, num_processes, options)
    else
      files_array = options[:files].split(/ /)
      groups = tests_in_groups(files_array || tests_folder, num_processes, options)
    end
    num_processes = groups.size

    #adjust processes to groups
    abort "no #{name}s found!" if groups.size == 0

    num_tests = groups.inject(0) { |sum, item| sum + item.size }
    puts "#{num_processes} processes for #{num_tests} #{name}s, ~ #{num_tests / groups.size} #{name}s per process"

    test_results = Parallel.map(groups, :in_processes => num_processes) do |group|
      run_tests(group, groups.index(group), options)
    end

    #parse and print results
    results = find_results(test_results.map { |result| result[:stdout] }*"")
    puts ""
    puts summarize_results(results)

    #report total time taken
    puts ""
    puts "Took #{Time.now - start} seconds"

    #exit with correct status code so rake parallel:test && echo 123 works
    failed = test_results.any? { |result| result[:exit_status] != 0 }
    abort "#{name.capitalize}s Failed" if failed
  end

  # parallel:spec[:count, :pattern, :options]
  def self.parse_rake_args(args)
    # order as given by user
    args = [args[:count], args[:pattern], args[:options]]

    # count given or empty ?
    # parallel:spec[2,models,options]
    # parallel:spec[,models,options]
    count = args.shift if args.first.to_s =~ /^\d*$/
    num_processes = count.to_i unless count.to_s.empty?
    num_processes ||= ENV['PARALLEL_TEST_PROCESSORS'].to_i if ENV['PARALLEL_TEST_PROCESSORS']
    num_processes ||= Parallel.processor_count

    pattern = args.shift
    options = args.shift

    [num_processes.to_i, pattern.to_s, options.to_s]
  end

  # finds all tests and partitions them into groups
  def self.tests_in_groups(root, num_groups, options)
    tests = find_tests(root, options)
    if options[:no_sort]
      Grouper.in_groups(tests, num_groups)
    else
      tests = with_runtime_info(tests)
      Grouper.in_even_groups_by_size(tests, num_groups, options)
    end
  end

  def self.execute_command(cmd, process_number, options)
    cmd = "TEST_ENV_NUMBER=#{test_env_number(process_number)} ; export TEST_ENV_NUMBER; #{cmd}"
    f = open("|#{cmd}", 'r')
    output = fetch_output(f, options)
    f.close
    {:stdout => output, :exit_status => $?.exitstatus}
  end

  def self.find_results(test_output)
    test_output.split("\n").map { |line|
      line = line.gsub(/\.|F|\*/, '')
      next unless line_is_result?(line)
      line
    }.compact
  end

  def self.test_env_number(process_number)
    process_number == 0 ? '' : process_number + 1
  end

  def self.runtime_log
    'tmp/parallelized_runtime_test.log'
  end

  def self.summarize_results(results)
    results = results.join(' ').gsub(/s\b/, '') # combine and singularize results
    counts = results.scan(/(\d+) (\w+)/)
    sums = counts.inject(Hash.new(0)) do |sum, (number, word)|
      sum[word] += number.to_i
      sum
    end
    sums.sort.map { |word, number| "#{number} #{word}#{'s' if number != 1}" }.join(', ')
  end

  protected

  # read output of the process and print in in chucks
  def self.fetch_output(process, options)
    all = ''
    buffer = ''
    timeout = options[:chunk_timeout] || 0.2
    flushed = Time.now.to_f

    while (char = process.getc)
      char = (char.is_a?(Fixnum) ? char.chr : char) # 1.8 <-> 1.9
      all << char

      # print in chunks so large blocks stay together
      now = Time.now.to_f
      buffer << char
      if flushed + timeout < now
        print buffer
        STDOUT.flush
        buffer = ''
        flushed = now
      end
    end

    # print the remainder
    print buffer
    STDOUT.flush

    all
  end

  # copied from http://github.com/carlhuda/bundler Bundler::SharedHelpers#find_gemfile
  def self.bundler_enabled?
    return true if Object.const_defined?(:Bundler)

    previous = nil
    current = File.expand_path(Dir.pwd)

    until !File.directory?(current) || current == previous
      filename = File.join(current, "Gemfile")
      return true if File.exists?(filename)
      current, previous = File.expand_path("..", current), current
    end

    false
  end

  def self.line_is_result?(line)
    line =~ /\d+ failure/
  end

  def self.with_runtime_info(tests)
    lines = File.read(runtime_log).split("\n") rescue []

    # use recorded test runtime if we got enough data
    if lines.size * 1.5 > tests.size
      puts "Using recorded test runtime"
      times = Hash.new(1)
      lines.each do |line|
        test, time = line.split(":")
        next unless test and time
        times[File.expand_path(test)] = time.to_f
      end
      tests.sort.map { |test| [test, times[test]] }
    else # use file sizes
      tests.sort.map { |test| [test, File.stat(test).size] }
    end
  end

  def self.find_tests(root, options)
    if root.is_a?(Array)
      root
    else
      # follow one symlink and direct children
      # http://stackoverflow.com/questions/357754/can-i-traverse-symlinked-directories-in-ruby-with-a-glob
      files = Dir["#{Rails.root}/**{,/*/**}/*#{test_suffix}"].uniq
      files = files.map { |f| f.sub(root+'/', '') }
      files = files.grep(/#{options['pattern']}/)
      files.map { |f| "#{root}/#{f}" }
    end
  end
end
