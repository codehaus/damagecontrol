# $Id: tunes.rb,v 1.1 2004/10/16 00:45:33 rinkrank Exp $
=begin
--------------------------------------------------------------------------
Copyright (c) 2002, Chris Morris
All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
this list of conditions and the following disclaimer in the documentation and/or
other materials provided with the distribution.

3. Neither the names Chris Morris, cLabs nor the names of contributors to this
software may be used to endorse or promote products derived from this software
without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS ``AS IS''
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--------------------------------------------------------------------------------
=end

require 'cl/xmlserial'
require 'rexml/document'

class Album
  include XmlSerialization

  attr_accessor :artist, :title, :tracks, :performers

  def initialize
    @tracks = []
    @performers = []
  end
end

class Track
  include XmlSerialization

  attr_accessor :name, :length
end

# I suppose this could be refactored down
# to an array instance var in AlbumDatabase
class AlbumCollection
  include XmlSerialization

  attr_accessor :albums

  def initialize
    @albums = []
  end

  def method_missing(methid, *args, &block)
    @albums.send(methid, *args, &block)
  end
end

class Option
  attr_reader :key, :desc

  def initialize(key, desc, aproc)
    @key = key
    @desc = desc
    @proc = aproc
  end

  def execute
    @proc.call
  end
end

class Options
  def initialize(opts)
    @opts = opts
  end

  def doOption(key)
    @opts.each do |opt|
      opt.execute if opt.key == key
    end
  end

  def option?(key)
    res = false
    @opts.each do |opt|
      res = true if opt.key == key
      break if res
    end
    res
  end

  def each
    @opts.each { |opt| yield opt if block_given? }
  end
end

class ConsolePrompt
  def ask
    puts
    @options.each do |option|
      puts "[#{option.key}]: #{option.desc}"
    end
    puts '------'
    print 'Do: '
    key = $stdin.gets[0..0].upcase
    puts
    @options.doOption(key) if @options.option?(key)
  end
end

class MainPrompt < ConsolePrompt
  def initialize(app)
    @app = app
    @options = Options.new(
      [Option.new("A", "Add album", Proc.new { @app.addAlbum }),
       Option.new("C", "Configure XmlSerialization", Proc.new { @app.conf_prompt }),
       Option.new("L", "List albums", Proc.new { @app.listAlbums }),
       Option.new("P", "Print XML", Proc.new { @app.print_xml }),
       Option.new("S", "Save collection", Proc.new { @app.save }),
       Option.new("X", "Exit", Proc.new { @app.doExit })
      ]
    )
  end
end

class XmlConfPrompt < ConsolePrompt
  def initialize(app)
    @app = app
    @options = Options.new(
      [Option.new("Y", "Output type elements", Proc.new { @app.turn_on_elements }),
       Option.new("N", "Do not output type elements", Proc.new { @app.turn_off_elements })
      ]
    )
  end
end

class AlbumDatabase
  def run
    if File.exists?("tunes.xml")
      doc = REXML::Document.new(File.open("tunes.xml"))
      @albums = AlbumCollection.from_xml(doc.root)
    else
      @albums = AlbumCollection.new
    end

    do_main_prompt
  end

  def do_main_prompt
    @prompt = MainPrompt.new(self)
    prompt
  end

  def prompt
    while true
      @prompt.ask
    end
  end

  def get(prompt)
    print prompt
    $stdin.gets.chomp
  end

  def addAlbum
    album = Album.new
    album.artist = get('Album artist: ')
    album.title = get('Album title: ')
    puts "Enter performers. Enter blank to end performer entry."
    while true
      perf = get('Performer: ')
      break if perf.empty?
      album.performers << perf
    end

    puts "Enter tracks. Enter blank track name to end track entry."
    while true
      track = Track.new
      track.name = get('Track name: ')
      break if track.name.empty?
      track.length = get('Track length: ')
      album.tracks << track
    end
    @albums << album
  end

  def conf_prompt
    @prompt = XmlConfPrompt.new(self)
    prompt
  end

  def listAlbums
    @albums.each do |album|
      print album.artist, ' :: ', album.title, "\n"
      album.performers.each do |cat|
        puts '  ' + cat
      end

      puts
      puts '  TRACKS'
      puts '  ======'
      album.tracks.each do |track|
        puts '  ' + track.name + ' ' + track.length
      end
    end
  end

  def print_xml
    @albums.to_xml.write($stdout, -1)
    puts "XSConf.outputTypeElements = " + XSConf.outputTypeElements.to_s
  end

  def turn_on_elements
    XSConf.outputTypeElements = true
    puts "XSConf.outputTypeElements = " + XSConf.outputTypeElements.to_s
    do_main_prompt
  end

  def turn_off_elements
    XSConf.outputTypeElements = false
    puts "XSConf.outputTypeElements = " + XSConf.outputTypeElements.to_s
    do_main_prompt
  end

  def save
    f = File.new("tunes.xml", File::CREAT|File::TRUNC|File::RDWR)
    begin
      @albums.to_xml.write(f, -1)
    ensure
      f.close
    end
  end

  def doExit
    exit
  end
end

AlbumDatabase.new.run