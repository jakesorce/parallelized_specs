# add rake tasks if we are inside Rails
if defined?(Rails::Railtie)
  class ParallelizedTests
    class Railtie < ::Rails::Railtie
      rake_tasks do
        load File.expand_path("../../tasks/parallelized_tests.rake.rake", __FILE__)
      end
    end
  end
end
