damagecontrol_home = File.expand_path("#{File.dirname($0)}/..")
script = "#{damagecontrol_home}/server/damagecontrol/tool/admin/#{File.basename($0)}"
system("ruby", "-W0", "-I#{damagecontrol_home}/server", script, *ARGV)
