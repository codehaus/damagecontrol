require 'rscm/abstract_scm'
require 'fileutils'

module RSCM
  class Monotone < AbstractSCM
    def initialize(db_file=nil, branch=nil, key=nil)
      @db_file = File.expand_path(db_file) if db_file
      @branch = branch
      @key = key
    end

    def name
      "Monotone"
    end

    def create
      FileUtils.mkdir_p(File.dirname(@db_file))
      cmd = "monotone --db=\"#{@db_file}\" db init"
      puts "*** Command: #{cmd}"
      safer_popen(cmd) {|io| io.read}
      
      #FIXME: should be somewhere else?
      cmd = "monotone --db=\"#{@db_file}\" read" 
      safer_popen(cmd, "r+") { |io|
        io.write <<EOF
[pubkey tester@test.net]
MIGdMA0GCSqGSIb3DQEBAQUAA4GLADCBhwKBgQCfN/cAMabgb6T7m8ksGnpQ7LO6hOdnc/7V
yivrRGtmpwSItljht1bmgLQF37KiSPoMEDUb1stfKxaMsYiy8iTyoQ+M2EVFP37n2rtnNZ0H
oVcQd2sRsCerQFh9nslRPymlkQXUlOiNFN6RlFNcdjkucqNe+YorFX21EYw7XuT5XwIBEQ==
[end]
[privkey tester@test.net]
npy0jyqbZdylFkMjdR9OvlqmDHuBGXpGFPt94h96aG+Lp+OdBCmWx8GueHk8FKkexwPqhRBM
PPopUeuwqxuSX+yEodMl5IHBmin0nLnbOeBjtasjemBFEmdNl/jPDF/AeQ2WHhanB731dSQc
vzLOQfKAYmfk56PPULi9oJJNUxaCkvsWtvaI+HUHZrjyyV7dA4Vsc6Jvx2Yf1+MdDAEGk/Rw
ZtP0LmuoiyvRDFqBF8aTmnotyb4kRKohnJ7VF+y6hYvmtMpM3TKnpR7EbojBzNPqKuO7nPUz
jGxA7F84O24Vbf128PNSI5vj4istow26aPjn28qPjfRrkV30WLL/dXfYJkfkTqglYnoEXvF/
xZoVxxNeAX58mgy0A1ErVxv8U7TwuP983GHEpLwy3gbiP+9akAJCr8r823DHmQqq5QDELibP
cuXZfOttpfVRkcbMhjeF0M6czc4HoKgHTAnf/18hzdZwGX/WWvRIBHImbUJ+mDbp2ByDTfKf
ErGXSvZ3HxCqBD8yx1SnXhV8IDHaBmV9wwYcN+H2cxOWGZk7g7xJS19+a3UQB3c3sSXQVJBp
6QpCZgysxkZwzuXDzzLZPT9SLZz4K2p7+7BwMbpy9ZxcyAzmiEtpA24UP06jtjFN7WcXAdx/
E5Gmoe9b1EiXWdReHjUGpc6k0LQ0PPXAwqrcGdwYbOLDZ5xsQ5AsEYSFtyTS60D1nHBcdNmW
M0eOUJFdJf/uNe/2EApc3a8TyEkZtVqiYtOVV3qDB9NmU4bVOkDqzl1F7zJwATWbmasSdkM3
6lxDkczBfCrEjH5p5Y8DU+ge4e4LRtknY9oBOJ7EQO0twYJg3k0=
[end]

EOF
        io.close_write
      }
    end

    def import(dir, message)
      dir = File.expand_path(dir)

      # post 0.17, this can be "cd dir && cmd add ."

      files = Dir["#{dir}/*"]
      dirs = files.find_all {|f| File.directory?(f)}
      relative_dirs = dirs.collect{|p| p[dir.length+1..-1]}
puts
puts relative_dirs.join("\n")
puts

      add_cmd = "monotone --db=\"#{@db_file}\" add #{relative_dirs.join(' ')}"
      commit_cmd = "monotone --db=\"#{@db_file}\" --branch=\"#{@branch}\" --key=\"#{@key}\" commit '#{message}'"

      puts "IMPORTING: #{add_cmd}"
      with_working_dir(dir) do
        safer_popen(add_cmd) do |stdout|
          stdout.each_line do |line|
            yield line if block_given?
          end
        end
        # FIXME: enter passphrase here: 'tester@test.net'
        safer_popen(commit_cmd) do |stdout|
          stdout.each_line do |line|
            yield line if block_given?
          end
        end
      end
    end

    def checked_out?(checkout_dir)
      monotone_dir = File.expand_path("#{checkout_dir}/MT")
      File.exists?(monotone_dir)
    end

    def uptodate?(checkout_dir, from_identifier)
      if (!checked_out?(checkout_dir))
        false
      else
      end
    end

    def checkout(checkout_dir)
      checkout_dir = PathConverter.filepath_to_nativepath(checkout_dir, false)
      mkdir_p(checkout_dir)
      checked_out_files = []
      if (checked_out?(checkout_dir))
        # update
      else
        checkout_cmd = "monotone --db=\"#{@db_file}\" --branch=\"#{@branch}\" --key=\"#{@key}\" checkout #{checkout_dir}"
        safer_popen(checkout_cmd) do |stdout|
          stdout.each_line do |line|
            yield line if block_given?
          end
        end
      end
    end
  end
end
