# Bootstrap file for RubyScript2Exe
# TODO: start daemon instead, and add a --webrick option to launch webrick forked
# TODO: make sure the app is unzipped to same tempdir each time (see rubyscript2exe doco)
load File.dirname(__FILE__) + '/script/server'