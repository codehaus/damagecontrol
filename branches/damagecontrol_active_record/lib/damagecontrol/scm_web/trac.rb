module DamageControl
  module ScmWeb
    class Trac
      attr_accessor :changeset_url
      
      def file_url(revision_file)
        revision = revision_file.revision
        # Trac doesn't seem to order files alphabetically!
        # http://dev.rubyonrails.com/changeset/1735
        # http://dev.rubyonrails.com/changeset/1522 (also, mix of added and modified futze the #file indexes)
        # TODO: grok Trac's sorting algo
        index = revision.revision_files.index(revision_file)
        "#{changeset_url}/#{revision.identifier}\#file#{index}"
      end
    end
  end
end