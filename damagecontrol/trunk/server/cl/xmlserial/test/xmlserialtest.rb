# $Id$
=begin
---------------------------------------------------------------------------
Copyright (c) 2002, Chris Morris
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

1. Redistributions of source code must retain the above copyright
notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in the
documentation and/or other materials provided with the distribution.

3. Neither the names Chris Morris, cLabs nor the names of contributors
to this software may be used to endorse or promote products derived from
this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS ``AS
IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
HOLDERS OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
---------------------------------------------------------------------------
=end

$LOAD_PATH << '..'
require 'xmlserial'
require 'test/unit'
require 'parsedate'
require 'singleton'

class PigBreedValue
  include Singleton

  attr_accessor :breedInitValue
end

class GuineaPig
  include XmlSerialization

  attr_accessor :breed, :children
  # attr_accessor :parent -- re-add later when fixing cyclic behavior

  def initialize
    @breed = PigBreedValue.instance.breedInitValue
    @children = []
    # @parent = nil
  end
end

module Pigs
  class Guinea
    include XmlSerialization

    attr_accessor :breed, :children
    # attr_accessor :parent

    def initialize
      @breed = PigBreedValue.instance.breedInitValue
      @children = []
    end
  end
end

module TestXmlSerial
  # TestNoAccessorsParamInitClass, which tests XmlSerialization's option
  # to skip the initialize method of a class needs to set this to true
  # because typeless element xml requires an initialize method
  @skipTypelessElementTests = false

  def makePig(breedValue, parent=nil, children=nil)
    pig = test_type.new
    pig.breed = breedValue
    pig.children = children if children != nil
    # pig.parent = parent if parent != nil
    pig
  end

  def doTestTransfer(gpsrc, expectedBreedOverride=nil)
    xml = gpsrc.to_xml
    xml.write($stdout, -1) if $VERBOSE
    gptarget = test_type.from_xml(xml)
    if expectedBreedOverride == nil
      assert_equal(gpsrc.breed, gptarget.breed)
    else
      assert_equal(expectedBreedOverride, gptarget.breed)
    end
    i = 0
    gpsrc.children.each do |srcchild|
      assert_equal(srcchild.breed, gptarget.children[i].breed)
      i += 1
    end
  end

  def doTestSimpleRoundTrip(breedValue, outputTypeElements, expectedBreedOverride=nil)
    if !(@skipTypelessElementTests && !outputTypeElements)
      XSConf.outputTypeElements = outputTypeElements
      PigBreedValue.instance.breedInitValue = breedValue
      gpsrc = makePig(breedValue)
      gpsrc.to_xml.write($stdout, -1) if $VERBOSE
      $stdout << "\n\n"               if $VERBOSE
      doTestTransfer(gpsrc, expectedBreedOverride)
    end
  end

  def doTestSimpleRoundTrips(breedValue)
    doTestSimpleRoundTrip(breedValue, false)
    doTestSimpleRoundTrip(breedValue, true)
  end

  def testString
    doTestSimpleRoundTrips('plain')
  end

  def testFixnum
    doTestSimpleRoundTrips(5)
  end

  def testBignum
    doTestSimpleRoundTrips(10 ** 20)
  end

  def testFloat
    doTestSimpleRoundTrips(5.4)
  end

  def testArray
    doTestSimpleRoundTrips(['plain', 'fun-loving', 5])
  end

  def testArrayFromXmlTypeElements
    doc = REXML::Document.new('<Array><String>a</String><String>b</String></Array>')
    ary = Array.from_xml(doc.root)
    assert_equal(['a', 'b'], ary)
  end

  def testArrayFromXmlNoTypeElementsAllStrings
    doc = REXML::Document.new('<Array>a,b,c</Array>')
    ary = Array.from_xml(doc.root)
    assert_equal(['a', 'b', 'c'], ary)
  end

  def testArrayFromXmlNoTypeElementsMixedSimple
    doc = REXML::Document.new('<Array>a,-5,5.4</Array>')
    ary = Array.from_xml(doc.root)
    assert_equal(['a', -5, 5.4], ary)
  end

  def testArrayFromXmlNoTypeElementsMixedSimpleKitchenSink
    doc = REXML::Document.new('<Array>5,-5,5.4,-5.4,5a,-5a,5.a,-5.a,4e5,0xaabb,123_456,0377,-0b101_000</Array>')
    ary = Array.from_xml(doc.root)
    expected = [5, -5, 5.4, -5.4, "5a", "-5a", "5.a", "-5.a", 400000.0, 43707, 123456, 255, -40]
    assert_equal(expected, ary)
  end

  def testEmptyArray
    doc = REXML::Document.new('<Array></Array>')
    ary = Array.from_xml(doc.root)
    assert_equal([], ary)

    doc = REXML::Document.new('<Array/>')
    ary = Array.from_xml(doc.root)
    assert_equal([], ary)
  end

  def testEmbeddedArray
    doTestSimpleRoundTrips(['plain', ['simple', 'but unique']])
  end

  def testSuicide
    doTestSimpleRoundTrips([5, ['simple', {'exception' => [2, 'two']}, [3, 4, 'pear']]])
  end

  def testHash
    doTestSimpleRoundTrips({'pigtype' => 'plain'})
  end

  def testBoolean
    doTestSimpleRoundTrips(true)
    doTestSimpleRoundTrips(false)
  end

  def testHashNoTypeElementsMixedSimple
    doc = REXML::Document.new('<Hash>a=5,6=b,c=d,7.4=4e5</Hash>')
    hash = Hash.from_xml(doc.root)
    assert_equal({'a'=>5, 6=>'b', 'c'=>'d', 7.4=>400000.0}, hash)
  end

  def doTestTime
    # trims off msecs which won't be XML-ized by default
    # timezone is also excluded because Time.gm won't take it
    strTime = Time.now.strftime(XSConf.timeFormat)
    val = Time.local(*ParseDate.parsedate(strTime)[0..5])

    doTestSimpleRoundTrips(val)
  end

  def testTime167OrGreater
    doTestTime if $".include?('time.rb')
  end

  def testTime166OrLess
    # fake out the loading if it's there
    $".delete('time.rb') if $".include?('time.rb')
    doTestTime
  end

  def testChildCustomClass
    pigsrc = makePig('hefty')
    pigsrc.children << makePig('market', pigsrc) << makePig('home', pigsrc) << makePig('roast beef', pigsrc)
    doTestTransfer(pigsrc)
  end

  def testXSUtilConvertSimpleType
    assert_equal(5, XmlSerialUtil.convertSimpleType("5"))
    assert_equal(-5, XmlSerialUtil.convertSimpleType("-5"))
    assert_equal(5.4, XmlSerialUtil.convertSimpleType("5.4"))
    assert_equal(-5.4, XmlSerialUtil.convertSimpleType("-5.4"))
    assert_equal("5a", XmlSerialUtil.convertSimpleType("5a"))
    assert_equal("-5a", XmlSerialUtil.convertSimpleType("-5a"))
    assert_equal("5.a", XmlSerialUtil.convertSimpleType("5.a"))
    assert_equal("-5.a", XmlSerialUtil.convertSimpleType("-5.a"))
    assert_equal(400000.0, XmlSerialUtil.convertSimpleType("4e5"))
    assert_equal(43707, XmlSerialUtil.convertSimpleType("0xaabb"))
    assert_equal(123456, XmlSerialUtil.convertSimpleType("123_456"))
    assert_equal(255, XmlSerialUtil.convertSimpleType("0377"))
    assert_equal(-40, XmlSerialUtil.convertSimpleType("-0b101_000"))
  end
end

class TestSimpleClass < Test::Unit::TestCase
  include TestXmlSerial

  def set_up
    XSConf.bypassInitialize = false
    @skipTypelessElementTests = false
  end

  def test_type
    GuineaPig
  end
end

class TestModuleClass < Test::Unit::TestCase
  include TestXmlSerial

  def set_up
    XSConf.bypassInitialize = false
    @skipTypelessElementTests = false
  end

  def test_type
    Pigs::Guinea
  end
end

class GuineaPigNA
  include XmlSerialization

  def initialize
    @breed = PigBreedValue.instance.breedInitValue
    @children = []
  end

  # yes, accessors, but with names other than attr_accessor
  # would make.
  # Here to allow makePig to work easily, but still
  # foils XmlSerialization if it doesn't work sans
  # accessors

  def get_breed
    @breed
  end

  def set_breed(value)
    @breed = value
  end

  def get_children
    @children
  end

  def set_children(value)
    @children = value
  end
end

class TestNoAccessorsClass < Test::Unit::TestCase
  include TestXmlSerial

  def set_up
    XSConf.bypassInitialize = false
    @skipTypelessElementTests = false
  end

  def test_type
    GuineaPigNA
  end

  # overrides TestXmlSerial#makePig
  def makePig(breedValue, children=nil)
    pig = test_type.new
    pig.set_breed breedValue
    pig.set_children children if children != nil
    pig
  end

  # overrides TestXmlSerial#doTestTransfer
  def doTestTransfer(gpsrc, expectedBreedOverride=nil)
    xml = gpsrc.to_xml
    xml.write($stdout, -1) if $VERBOSE
    gptarget = test_type.from_xml(xml)
    if expectedBreedOverride == nil
      assert_equal(gpsrc.get_breed, gptarget.get_breed)
    else
      assert_equal(expectedBreedOverride, gptarget.get_breed)
    end
    i = 0
    gpsrc.get_children.each do |srcchild|
      assert_equal(srcchild.get_breed, gptarget.get_children[i].get_breed)
      i += 1
    end
  end

  # overrides TestXmlSerial#testChildCustomClass
  def testChildCustomClass
    pigsrc = makePig('hefty')
    pigsrc.get_children << makePig('market') << makePig('home') << makePig('roast beef')
    doTestTransfer(pigsrc)
  end
end

class GuineaPigNAParamInit
  include XmlSerialization

  def initialize(breed, children)
    @breed = breed
    @children = children
  end

  # yes, accessors, but with names other than attr_accessor
  # would make.
  # Here to allow makePig to work easily, but still
  # foils XmlSerialization if it doesn't work sans
  # accessors

  def get_breed
    @breed
  end

  def set_breed(value)
    @breed = value
  end

  def get_children
    @children
  end

  def set_children(value)
    @children = value
  end
end

class TestNoAccessorsParamInitClass < Test::Unit::TestCase
  include TestXmlSerial

  def set_up
    XSConf.bypassInitialize = true
    @skipTypelessElementTests = true
  end

  def test_type
    GuineaPigNAParamInit
  end

  # overrides TestXmlSerial#makePig
  def makePig(breedValue, children=[])
    pig = test_type.new(breedValue, children)
    pig
  end

  # overrides TestXmlSerial#doTestTransfer
  def doTestTransfer(gpsrc, expectedBreedOverride=nil)
    xml = gpsrc.to_xml
    xml.write($stdout, -1) if $VERBOSE
    gptarget = test_type.from_xml(xml)
    if expectedBreedOverride == nil
      assert_equal(gpsrc.get_breed, gptarget.get_breed)
    else
      assert_equal(expectedBreedOverride, gptarget.get_breed)
    end
    i = 0
    gpsrc.get_children.each do |srcchild|
      assert_equal(srcchild.get_breed, gptarget.get_children[i].get_breed)
      i += 1
    end
  end

  # overrides TestXmlSerial#testChildCustomClass
  def testChildCustomClass
    pigsrc = makePig('hefty')
    pigsrc.get_children << makePig('market') << makePig('home') << makePig('roast beef')
    doTestTransfer(pigsrc)
  end
end

class GuineaPigUninit
  include XmlSerialization

  attr_accessor :breed
end

class TestUninitPig < Test::Unit::TestCase
  def set_up
    XSConf.bypassInitialize = false
    @skipTypelessElementTests = false
  end

  def testFixnumGrok
    doc = REXML::Document.new('<GuineaPigUninit><breed>60</breed></GuineaPigUninit>')
    pig = GuineaPigUninit.from_xml(doc.root)
    assert_equal(60, pig.breed)
  end
end

class TestString < Test::Unit::TestCase
  def testNilTextInElement
    e = REXML::Element.new('Test')
    assert_equal(nil, String.from_xml(e))
  end
end

$VERBOSE = ARGV.include?('-v')
# delete this so it doesn't muck up Test::Unit regexp ARGV stuff
ARGV.delete('-v') if $VERBOSE