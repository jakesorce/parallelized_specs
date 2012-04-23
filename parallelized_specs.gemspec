# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "parallelized_specs"
  s.version = "0.0.8"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Jake Sorce, Bryan Madsen"]
  s.date = "2012-04-23"
  s.email = "jake@instructure.com"
  s.executables = ["parallelized_spec"]
  s.files = [
    "Gemfile",
    "Gemfile.lock",
    "Rakefile",
    "Readme.md",
    "VERSION",
    "bin/parallelized_spec",
    "lib/parallelized_specs.rb",
    "lib/parallelized_specs/grouper.rb",
    "lib/parallelized_specs/railtie.rb",
    "lib/parallelized_specs/runtime_logger.rb",
    "lib/parallelized_specs/spec_error_count_logger.rb",
    "lib/parallelized_specs/spec_error_logger.rb",
    "lib/parallelized_specs/spec_failures_logger.rb",
    "lib/parallelized_specs/spec_logger_base.rb",
    "lib/parallelized_specs/spec_runtime_logger.rb",
    "lib/parallelized_specs/spec_start_finish_logger.rb",
    "lib/parallelized_specs/spec_summary_logger.rb",
    "lib/parallelized_specs/tasks.rb",
    "lib/tasks/parallelized_specs.rake",
    "parallelized_specs.gemspec",
    "spec/parallelized_specs/spec_failure_logger_spec.rb",
    "spec/parallelized_specs/spec_runtime_logger_spec.rb",
    "spec/parallelized_specs/spec_summary_logger_spec.rb",
    "spec/parallelized_specs_spec.rb",
    "spec/spec_helper.rb"
  ]
  s.homepage = "http://github.com/jakesorce/parallelized_specs"
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.22"
  s.summary = "Run rspec tests in parallel"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end

