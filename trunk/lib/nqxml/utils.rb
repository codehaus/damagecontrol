#
# Copyright (c) 2001 by Jim Menard <jimm@io.com>
#
# Released under the same license as Ruby. See
# http://www.ruby-lang.org/en/LICENSE.txt.
#

require 'nqxml/error'

module NQXML

    # Returns string with entities replaced.
    def NQXML.encode(str)
	copy = str.gsub('&', '&amp;')
	copy.gsub!('<', '&lt;')
	copy.gsub!('>', '&gt;')
	copy.gsub!('"', '&quot;')
	copy.gsub!('\'', '&apos;')
	return copy
    end

    # Returns a new string with all of the #NNN; and #xXXX; character refs
    # replaced by the characters they represent.
    def NQXML.replaceCharacterRefs(str)
	return nil if str.nil?
	copy = str.gsub(/&\#(\d+);/n) { $1.to_i.chr }
	return copy.gsub(/&\#x([0-9a-f]+);/ni) { $1.hex.chr }
    end

    # Returns a new string with all of the special character refs (for
    # example, &amp; and &lt;) replaced by the characters they represent.
    def NQXML.replacePredefinedEntityRefs(str)
	return nil if str.nil?
	copy = str.gsub(/&amp;/n, '&')
	copy.gsub!(/&quot;/n, '"')
	copy.gsub!(/&apos;/n, '\'')
	copy.gsub!(/&gt;/n, '>')
	copy.gsub!(/&lt;/n, '<')
	return copy
    end

end
