# call this controller from your selenium tests to set up test data 
# using the 'open' command, the second column should contain the url
# eg. "open /testdata" for the default fixture
# eg. "open /testdata/clean" for a clean database
# eg. "open /testdata/specialfixture" for some specially tweaked fixture

# only load in development and test environment
if ['development', 'test'].include?(RAILS_ENV) then

  # TODO require the fixture stuff
  class TestdataController < ActionController::Base
    # add fixtures that you need for test data
    # fixture :items

    def index
      # default test data, the fixtures as above
      FileUtils.rm_rf(BASEDIR)
      render_text "Default test data setup"
    end

    def clean
      # completely empty database
      # TODO how to completely clean out all the data from the fixtures?
      FileUtils.rm_rf(BASEDIR)
      render_text "All data cleaned"
    end

    # add more test data fixtures by adding actions here 
    # and calling them from your selenium test 
  end
  
end
