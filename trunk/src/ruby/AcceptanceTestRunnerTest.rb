require 'test/unit'
require 'mockit'

require 'AcceptanceTestRunner'

class AcceptanceTestRunnerTest < Test::Unit::TestCase

TEST_WITH_STORY_ENTRY =
<<-EOF
STORY: This is a very short story.
And this is the another line of the story.
EOF

  def test_parses_story_entry
    runner = AcceptanceTestRunner.new(nil)
    runner.parse_string(TEST_WITH_STORY_ENTRY)
    assert_equal(%{This is a very short story.
And this is the another line of the story.}, runner.story)
  end

TEST_WITH_STORY_AND_TEST =
<<-EOF
STORY: This is a very short story.
And this is the another line of the story.

TEST: This is a very short test.
EOF

  def test_parses_test_with_test_and_story
    runner = AcceptanceTestRunner.new(nil)
    runner.parse_string(TEST_WITH_STORY_AND_TEST)
    assert_equal(%{This is a very short story.
And this is the another line of the story.}, runner.story)
    assert_equal("This is a very short test.", runner.tests[0].description)
  end

TEST_WITH_ONE_STEP =
<<-EOF
STORY: This is a very short story.

TEST: This is a very short test.
Do something
EOF

  def test_parses_test_with_one_step
    runner = AcceptanceTestRunner.new(nil)
    runner.parse_string(TEST_WITH_ONE_STEP)
    assert_equal(1, runner.tests[0].steps.size)
    assert_equal("Do something", runner.tests[0].steps[0].task)
  end

TEST_WITH_SOME_STEPS =
<<-EOF
STORY: This is a very short story.

TEST: This is a very short test.
Do something
Do something more
Do something once again
EOF

  def test_parses_test_with_some_steps
    runner = AcceptanceTestRunner.new(nil)
    runner.parse_string(TEST_WITH_SOME_STEPS)
    assert_equal(3, runner.tests[0].steps.size)
    assert_equal("Do something", runner.tests[0].steps[0].task)
    assert_equal("Do something more", runner.tests[0].steps[1].task)
    assert_equal("Do something once again", runner.tests[0].steps[2].task)
  end

TEST_WITH_SOME_STEPS_WITH_ARGUMENTS =
<<-EOF
STORY: This is a very short story.

TEST: This is a very short test.
Do something : argument1 argument2
Do something more : other_argument1 other_argument2
EOF

  def test_parses_test_with_some_steps_and_arguments
    runner = AcceptanceTestRunner.new(nil)
    runner.parse_string(TEST_WITH_SOME_STEPS_WITH_ARGUMENTS)
    assert_equal(2, runner.tests[0].steps.size)
    assert_equal("Do something", runner.tests[0].steps[0].task)
    assert_equal("argument1", runner.tests[0].steps[0].args[0])
    assert_equal("argument2", runner.tests[0].steps[0].args[1])
    assert_equal("Do something more", runner.tests[0].steps[1].task)
    assert_equal("other_argument1", runner.tests[0].steps[1].args[0])
    assert_equal("other_argument2", runner.tests[0].steps[1].args[1])
  end
  
TEST_WITH_MULTI_LINE_ARGUMENTS_TASK_AFTER =
<<-EOF
STORY: This is a very short story.

TEST: This is a very short test.
Do something with complicated arguments : simple_argument1 simple_argument2
  This is the first line of a multi line argument
  This is the second line of a multi line argument
Task after
EOF
  
TEST_WITH_MULTI_LINE_ARGUMENTS_TASK_BEFORE =
<<-EOF
STORY: This is a very short story.

TEST: This is a very short test.
Task before
Do something with complicated arguments : simple_argument1 simple_argument2
  This is the first line of a multi line argument
  This is the second line of a multi line argument
EOF

  def test_parses_step_with_multi_line_argument_and_step_before
    runner = AcceptanceTestRunner.new(nil)
    runner.parse_string(TEST_WITH_MULTI_LINE_ARGUMENTS_TASK_BEFORE)
    assert_equal(2, runner.tests[0].steps.size)
    assert_equal("Task before", runner.tests[0].steps[0].task)
    check_multi_line_step(runner.tests[0].steps[1])
  end

  def test_parses_step_with_multi_line_argument_and_step_after
    runner = AcceptanceTestRunner.new(nil)
    runner.parse_string(TEST_WITH_MULTI_LINE_ARGUMENTS_TASK_AFTER)
    assert_equal(2, runner.tests[0].steps.size)
    check_multi_line_step(runner.tests[0].steps[0])
    assert_equal("Task after", runner.tests[0].steps[1].task)
  end

TEST_WITH_COLON_IN_ARGUMENT =
<<-EOF
STORY: This is a very short story.

TEST: Test
Check out or update CVS project : :ext:dcontrol@cvs.codehaus.org:/cvsroot/damagecontrol damagecontrolled
EOF

  def test_handles_colons_in_arguments
    runner = AcceptanceTestRunner.new(nil)
    runner.parse_string(TEST_WITH_COLON_IN_ARGUMENT)
    assert_equal("Check out or update CVS project", runner.tests[0].steps[0].task)
    assert_equal([":ext:dcontrol@cvs.codehaus.org:/cvsroot/damagecontrol", "damagecontrolled"], 
      runner.tests[0].steps[0].args)
  end
  
  def check_multi_line_step(step)
    assert_equal("Do something with complicated arguments", step.task)
    assert_equal(["simple_argument1", "simple_argument2",
      %{This is the first line of a multi line argument
This is the second line of a multi line argument} ], step.args)
  end

def test_task_converted_to_method_name_with_underscores
    step = TestStep.new("This is a single test step", [])
    assert_equal("this_is_a_single_test_step", step.method_name)
  end
  
  def test_executing_test_step_runs_method_on_test_driver
    driver = Mock.new
    driver.__setup(:respond_to?) { true }
    
    driver.__expect(:test_step1) {}
    driver.__expect(:test_step2) {|*args|  assert_equal(["arg1", "arg2"], args) }
    TestStep.new("Test step1", []).execute(driver)
    TestStep.new("Test step2", ["arg1", "arg2"]).execute(driver)
    driver.__verify
  end
  
  class FailingDriver
    include Test::Unit::Assertions
    
    def check_that_this_is_the_correct_content(content)
      assert_equal(%{A little bit of this.
A little bit of that.}, content)
    end
    
    def break_the_test
      fail
    end
  end
  
  def test_run_failing_test_from_file
    runner = AcceptanceTestRunner.new("failing_test.txt")
    runner.add_driver(FailingDriver.new)
    assert_raises(RuntimeError) { runner.run }
  end
  
  def test_missing_method_throws_exception_with_clear_message
    runner = AcceptanceTestRunner.new(nil)
    test = AcceptanceTest.new("Failing test")
    test.steps<<TestStep.new("This task is not implemented", [])
    runner.tests<<test
    runner.add_driver(Object.new)
    assert_raises(NoMethodError) { runner.run }
  end

end
