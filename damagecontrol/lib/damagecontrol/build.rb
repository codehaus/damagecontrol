module DamageControl
  # File structure
  #
  #   .damagecontrol/
  #     SomeProject/
  #       project.yaml
  #       checkout/
  #       changesets/
  #         2802/
  #           changeset.yaml         (serialised ChangeSet object)
  #           diffs/                 (serialised diff files)
  #           builds/                
  #             2005280271234500/    (timestamp of build start)
  #               stdout.log
  #               stderr.log
  #               artifacts/
  #
  class Build
    def initialize(changeset)
      @changeset = changeset
    end
  end
end