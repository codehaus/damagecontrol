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
Contributors:
  Harry Ohlsen [harryo@zip.com.au]
  Stefan Mueller [flcl@gmx.net]
=end

require 'rexml/document'
require 'singleton'
require 'parsedate'
begin
  require 'time'
rescue LoadError
  # don't do anything
end

class Object
  def make_type_element
    if defined? type.name
      element = REXML::Element.new(type.name.gsub('::', '-'))
    else
      element = REXML::Element.new(type.class.to_s.gsub('::', '-'))
    end
  end

  # this method mainly gets things in order with the XML element
  # then calls instance_data_to_xml to actually get the data
  def to_xml(parentElement=nil)
    if parentElement == nil
      element = make_type_element
    else
      if XSConf.outputTypeElements || type_elements_required?
        element = make_type_element
        parentElement.add_element(element)
      else
        element = parentElement
      end
    end
    instance_data_to_xml(element)
    element
  end

  def instance_data_to_xml(element)
    raise "instance_data_to_xml must be defined for " + self.type.name
  end

  # Descendant classes can override this to force type elements
  # to be output. Array and Hash use this depending on their contents
  def type_elements_required?
    false
  end
end

class Class
  def new_without_initialize( *args )
    self.class_eval %{
      alias :old_initialize_with_args :initialize
      def initialize( *args ); end
    }
    begin
      result = self.new( *args )
    ensure
      self.class_eval %{
        undef :initialize
        alias :initialize :old_initialize_with_args
      }
    end

    result
  end
end

# Singleton configuration class. See XSConf.
# outputTypeElements:: boolean value that controls whether or not type
#                      elements are output in the XML. Default is true.
# timeFormat:: format string used for input/output of Time types. Default
#              is %Y-%b-%d %H:%M:%S
# bypassInitialize:: when creating class instances during from_xml calls,
#                    setting bypassInitialize to true will not call the
#                    initialize method. This allows classes with parameterized
#                    initializers to be instantiated. Default is false.
class XmlSerialConf
  include Singleton

  attr_accessor :outputTypeElements, :timeFormat, :bypassInitialize

  def initialize
    @outputTypeElements = true
    @bypassInitialize = false
    @timeFormat = '%Y-%b-%d %H:%M:%S'
  end
end

# convenience constant to refer to singleton XmlSerialConf class
XSConf = XmlSerialConf.instance

# Utility singleton methods for internal use
class XmlSerialUtil
  # method to convert XML element text from String into the proper
  # simple type. For example, the string "5" is converted to
  # Fixnum 5
  def XmlSerialUtil.convertSimpleType(value)
    # Many thanks to Dave Thomas for this one. Saved me from regexp hell.
    Integer(value) rescue Float(value) rescue value
  end

  # utility method for finding a class within a module hierarchy
  def XmlSerialUtil.find_class(name)
    subclasses = name.gsub("-", "::").split("::")

    c = Object

    subclasses.each do |s|
      c = c.const_get(s)
    end
    c
  end
end

# convenience constant to refer to XmlSerialUtil
XSUtil = XmlSerialUtil

class XmlSerialCyclicalReferenceCop
  include Singleton
  
  def initialization
    @idlist = []
  end
  
  def police_id(id)
    if @idlist.include?(id)
      false
    else
      @idlist << id
      true
    end
  end
end

module XmlSerialization
  # refactoring -- make a generic REXML wrapper in a separate unit
  # that would allow others to more easily substitute in their own
  # xml parsing engine

  # called by to_xml method added to the Object class.
  def instance_data_to_xml(element)
    instance_variables.each do |instanceVarName|
      instanceVarName.sub!(/@/, '')
      instanceVarName.sub!(/::/, '-')
      instanceVarValue = self.instance_eval "@#{instanceVarName}"
      if instanceVarValue != nil
        instanceElement = element.add_element(instanceVarName)
        self.instance_eval "instanceValue = (@#{instanceVarName}).to_xml(instanceElement)"
      end
    end
  end

  def XmlSerialization.append_features(includingClass)
    # [ruby-talk:14976] - append_features makes from_xml a
    # singleton/class method in the including class. The call to super is
    # required to make this work properly
    super
    def includingClass.from_xml(element)
      if XSConf.bypassInitialize
        obj = self.new_without_initialize
      else
        obj = new
      end
      element.elements.each do |instanceElement|
        instanceVarName = instanceElement.name
        if instanceElement.has_elements?
          childElement = instanceElement.elements[1]
          typeName = childElement.name
        else
          childElement = instanceElement
          instanceVar = obj.instance_eval "@#{instanceVarName}"
          if instanceVar.instance_of? NilClass
            value = XSUtil.convertSimpleType(instanceElement.text)
            obj.instance_eval "@#{instanceVarName} = value"
            next
          else
            typeName = instanceVar.type.name
          end
        end
        value = XSUtil.find_class(typeName).from_xml(childElement)
        obj.instance_eval "@#{instanceVarName} = value"
      end
      obj
    end
  end
end

# all from_xml are class methods, because self modifying instances
# are a hassle, and not needed

class String
  def to_xml_text
    # String is duped in case it's frozen. Xml processing might alter it
    # by removing white-space, etc.
    self.dup
  end

  def instance_data_to_xml(element)
    element.add_text(to_xml_text)
  end

  def String.from_xml(element)
    if element.text != nil
      # puts 'element.text.tainted? = ' + element.text.tainted?.to_s
      String.new(element.text)
    else
      nil
    end
  end
end

class Numeric
  def to_xml_text
    self.to_s
  end

  def instance_data_to_xml(element)
    element.add_text(to_xml_text)
  end
end

class Integer
  def Integer.from_xml(element)
    element.text.to_i
  end
end

class Float
  def Float.from_xml(element)
    element.text.to_f
  end
end

class Time
  def to_xml_text
    self.strftime(XSConf.timeFormat)
  end

  def instance_data_to_xml(element)
    element.add_text(to_xml_text)
  end

  def Time.from_xml(element)
    # time.rb added in Ruby 1.6.7
    if $".include?('time.rb')
      Time.parse(element.text)
    else
      Time.local(*ParseDate.parsedate(element.text)[0..5])
    end
  end
end

class Array
  def type_elements_required?
    !all_items_types_support_no_type_elements?
  end

  def type_supports_no_type_element?(item)
    (item.kind_of? String) || (item.kind_of? Numeric)
  end

  def all_items_types_support_no_type_elements?
    result = true
    each do |item|
      if !type_supports_no_type_element?(item)
        result = false
        break
      end
    end
    result
  end

  def Array.no_type_elements_delimiter
    ","
  end

  def instance_data_to_xml(element)
    outputTypeElements =
      XSConf.outputTypeElements || type_elements_required?

    if outputTypeElements
      orig = XSConf.outputTypeElements
      XSConf.outputTypeElements = true
      each do |item|
        item.to_xml(element)
      end
      XSConf.outputTypeElements = orig
    else
      text = ''
      each do |item|
        text = text + Array.no_type_elements_delimiter if !text.empty?
        text = text + item.to_xml_text
      end
      element.add_text(text)
    end
  end

  def Array.from_xml(element)
    result = []
    if element.has_elements?
      element.elements.each do |itemElement| # itemElement = '<[type]>'
        childElement = itemElement
        typeName = childElement.name
        result << XSUtil.find_class(typeName).from_xml(childElement)
      end
    else
      text = element.text
      if text != nil
        result = text.split(Array.no_type_elements_delimiter)
        result.collect! do |item| XSUtil.convertSimpleType(item) end
      end
    end
    result
  end
end

class Hash
  def type_elements_required?
    !all_items_types_support_no_type_elements?
  end

  # refactor? Copy of method in Array, but where is a one-time place for it?
  def type_supports_no_type_element?(item)
    (item.kind_of? String) || (item.kind_of? Numeric)
  end

  def all_items_types_support_no_type_elements?
    result = true
    each do |key, value|
      if !type_supports_no_type_element?(key)
        result = false
        break
      end

      if !type_supports_no_type_element?(value)
        result = false
        break
      end
    end
    result
  end

  def Hash.pair_delimiter
    ","
  end

  def Hash.key_value_delimiter
    "="
  end

  def instance_data_to_xml(element)
    outputTypeElements =
      XSConf.outputTypeElements || type_elements_required?

    if outputTypeElements
      orig = XSConf.outputTypeElements
      XSConf.outputTypeElements = true
      each do |key, value|
        pairElement = REXML::Element.new('Pair')
        element.add_element(pairElement)

        keyElement = REXML::Element.new('Key')
        pairElement.add_element(keyElement)
        key.to_xml(keyElement)

        valueElement = REXML::Element.new('Value')
        pairElement.add_element(valueElement)
        value.to_xml(valueElement)
      end
      XSConf.outputTypeElements = orig
    else
      text = ''
      each do |key, value|
        text = text + Hash.pair_delimiter if !text.empty?
        text = text + key.to_xml_text + Hash.key_value_delimiter + value.to_xml_text
      end
      element.add_text(text)
    end
  end

  def Hash.from_xml(element)
    result = {}
    if element.has_elements?
      element.each_element do |pairElement|
        keyElement = pairElement.elements[1]
        keyTypeElement = keyElement.elements[1]
        key = XSUtil.find_class(keyTypeElement.name).from_xml(keyTypeElement)

        valueElement = pairElement.elements[2]
        valueTypeElement = valueElement.elements[1]
        value = XSUtil.find_class(valueTypeElement.name).from_xml(valueTypeElement)

        result[key] = value
      end
    else
      text = element.text
      if text != nil
        ary = text.split(Hash.pair_delimiter)
        ary.each do |pair|
          key, value = pair.split(Hash.key_value_delimiter)
          key = XSUtil.convertSimpleType(key)
          value = XSUtil.convertSimpleType(value)
          result[key] = value
        end
      end
    end
    result
  end
end

class TrueClass
  def to_xml_text
    self.to_s
  end
  def instance_data_to_xml(element)
    element.add_text(to_xml_text)
  end
  def TrueClass.from_xml(element)
    true
  end
end

class FalseClass
  def to_xml_text
    self.to_s
  end
  def instance_data_to_xml(element)
    element.add_text(to_xml_text)
  end
  def FalseClass.from_xml(element)
    false
  end
end
