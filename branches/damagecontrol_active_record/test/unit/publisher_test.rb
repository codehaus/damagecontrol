require File.dirname(__FILE__) + '/../test_helper'
require 'damagecontrol/publisher/base'

class PublisherTest < Test::Unit::TestCase
  fixtures :publishers

  def test_should_persist_publisher
    pub = Publisher.create(:delegate => DamageControl::Publisher::Jabber.new, :enabled => true)
    pub.reload
    assert_equal("Jabber", pub.delegate.name)
    assert(pub.enabled)
  end
end
