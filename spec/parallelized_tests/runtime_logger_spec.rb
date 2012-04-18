require 'spec_helper'

describe ParallelizedTests::RuntimeLogger do

  describe :writing do
    it "overwrites the runtime_log file on first log invocation" do
      class FakeTest
      end
      test = FakeTest.new
      time = Time.now
      File.open(ParallelizedTests.runtime_log, 'w'){ |f| f.puts("FooBar") }
      ParallelizedTests::RuntimeLogger.send(:class_variable_set,:@@has_started, false)
      ParallelizedTests::RuntimeLogger.log(test, time, Time.at(time.to_f+2.00))
      result = File.read(ParallelizedTests.runtime_log)
      result.should_not include('FooBar')
      result.should include('test/fake_test.rb:2.00')
    end

    it "appends to the runtime_log file after first log invocation" do
      class FakeTest
      end
      test = FakeTest.new
      class OtherFakeTest
      end
      other_test = OtherFakeTest.new

      time = Time.now
      File.open(ParallelizedTests.runtime_log, 'w'){ |f| f.puts("FooBar") }
      ParallelizedTests::RuntimeLogger.send(:class_variable_set,:@@has_started, false)
      ParallelizedTests::RuntimeLogger.log(test, time, Time.at(time.to_f+2.00))
      ParallelizedTests::RuntimeLogger.log(other_test, time, Time.at(time.to_f+2.00))
      result = File.read(ParallelizedTests.runtime_log)
      result.should_not include('FooBar')
      result.should include('test/fake_test.rb:2.00')
      result.should include('test/other_fake_test.rb:2.00')
    end

  end

  describe :formatting do
    it "formats results for simple test names" do
      class FakeTest
      end
      test = FakeTest.new
      time = Time.now
      ParallelizedTests::RuntimeLogger.message(test, time, Time.at(time.to_f+2.00)).should == 'test/fake_test.rb:2.00'
    end

    it "formats results for complex test names" do
      class AVeryComplex
        class FakeTest
        end
      end
      test = AVeryComplex::FakeTest.new
      time = Time.now
      ParallelizedTests::RuntimeLogger.message(test, time, Time.at(time.to_f+2.00)).should == 'test/a_very_complex/fake_test.rb:2.00'
    end

    it "guesses subdirectory structure for rails test classes" do
      module Rails
      end
      class ActionController
        class TestCase
        end
      end
      class FakeControllerTest < ActionController::TestCase
      end
      test = FakeControllerTest.new
      time = Time.now
      ParallelizedTests::RuntimeLogger.message(test, time, Time.at(time.to_f+2.00)).should == 'test/functional/fake_controller_test.rb:2.00'
    end
  end

end
