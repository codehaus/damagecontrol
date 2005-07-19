require File.dirname(__FILE__) + '/../../../test_helper'

module DamageControl
  module Publisher
    class SoundTest < Test::Unit::TestCase
      fixtures :builds, :projects, :revisions

      def test_should_play_sound_on_local_machine_on_publish
        Sound.new.publish(@build_1)
        # hard to assert success. verify audibly.
      end
    end
  end
end