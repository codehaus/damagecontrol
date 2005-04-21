module DamageControl
  class Builder
    def build(changeset, reason)
      changeset.build!(project, reason) do |build|
        changeset.project.publish(build)
      end
      
      def can_build?(changeset)
        true
      end
    end
  end
end