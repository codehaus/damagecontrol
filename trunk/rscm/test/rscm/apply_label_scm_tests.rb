require 'fileutils'

module RSCM
  module GenericSCMTests
    include FileUtils

    def test_apply_label
      work_dir = new_temp_dir
      checkout_dir = "#{work_dir}/checkout"
      repository_dir = "#{work_dir}/repository"
      scm = create_scm(repository_dir, "damagecontrolled")
      scm.create

      import_damagecontrolled(scm, "#{work_dir}/damagecontrolled")
      scm.checkout(checkout_dir)

      add_or_edit_and_commit_file(scm, checkout_dir, "before.txt", "Before label")
      scm.apply_label(checkout_dir, "MY_LABEL")
      add_or_edit_and_commit_file(scm, checkout_dir, "after.txt", "After label")
      scm.checkout(checkout_dir, "MY_LABEL")
      assert(File.exist?("#{checkout_dir}/before.txt"))
      assert(!File.exist?("#{checkout_dir}/after.txt"))
    end

  end
end