require File.dirname(__FILE__) + '/../test_helper'

class PublisherTest < Test::Unit::TestCase
  fixtures :publishers
  include MockIt

  def test_should_persist_delegate
    pub = Publisher.create(:delegate => DamageControl::Publisher::Jabber.new)
    pub.reload
    assert_equal("Jabber", pub.delegate.name)
  end
  
  def test_should_publish_if_successful_enabled
    build = Build.create(:reason => Build::SCM_POLLED, :state => Build::Fixed.new)
    
    pub = Publisher.create
    pub.delegate = new_mock
    pub.publish(build)
    pub.delegate.__verify

    pub.enabling_states = [Build::Fixed]
    pub.delegate.__expect(:publish){|b| assert_same(build, b)}
    pub.publish(build)
    pub.delegate.__verify
  end
end
