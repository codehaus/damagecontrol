# so the "clean and secure" version
readme, writeme = IO.pipe
pid = fork {
    # child
    $stdout = writeme
    readme.close
    exec('find', '..')
}
# parent
Process.waitpid(pid, 0)
writeme.close
while readme.gets do
    # do something with $_
end