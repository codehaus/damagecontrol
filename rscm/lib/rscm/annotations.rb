class Class
  @@anns = {}

  # Defines annotation(s) for the next defined +attr_reader+ or
  # +attr_accessor+. The +anns+ argument should be a Hash defining annotations
  # for the associated attr. Example:
  #
  #   require 'rscm/annotations'
  #
  #   class EmailSender
  #     ann :description => "IP address of the mail server", :tip => "Use 'localhost' if you have a good box, sister!"
  #     attr_accessor :server
  #   end
  #
  # The EmailSender class' annotations can then be accessed like this:
  #
  #   EmailSender.server[:description] # => "IP address of the mail server"
  #
  # Yeah right, cool, whatever. What's this good for? It's useful for example if you want to
  # build some sort of user interface (for example in on Ruby on Rails) that allows editing of
  # fields, and you want to provide an explanatory text and a tooltip in the UI.
  #
  # You may also use annotations to specify more programmatically meaningful metadata. More power to you.
  # 
  def ann(anns)
    $attr_anns ||= {}
    $attr_anns.merge!(anns)
    def self.method_missing(sym, *args) #:nodoc:
      @@anns[sym] || {}
    end
  end

  alias old_attr_reader attr_reader #:nodoc:
  def attr_reader(*syms) #:nodoc:
    syms.each do |sym|
      @@anns[sym] = $attr_anns.dup if $attr_anns
    end
    $attr_anns = nil
    old_attr_reader(*syms)
  end

  def attr_accessor(*syms) #:nodoc:
    attr_reader(*syms)
    attr_writer(*syms)
  end
end
