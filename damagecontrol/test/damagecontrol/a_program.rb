$stderr.write("this\nis\nstderr\n#{ENV['foo']}")
$stdout.write("this\nis\nstdout\n#{ARGV[0]}")
exit(ARGV[0].to_i)
