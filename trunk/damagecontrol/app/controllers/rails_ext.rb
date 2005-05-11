require 'rscm/annotations'

class ActionController::Base

  # Instantiates an Array of object from +class_name_2_attr_hash_hash+
  # which should be a hash where the keys are class names and the values
  # a Hash containing {attr_name => attr_value} pairs.
  def instantiate_array_from_hashes(class_name_2_attr_hash_hash)
    result = []
    class_name_2_attr_hash_hash.each do |class_name, attr_hash|
      result << instantiate_from_hash(eval(class_name), attr_hash)
    end
    result
  end

  def instantiate_from_hash(clazz, attr_hash)
    object = clazz.new
    attr_hash.each do |attr_name, attr_value|
      setter = attr_name[1..-1] + "="
      object.__send__(setter.to_sym, attr_value) if object.respond_to?(setter.to_sym)
    end
    object
  end

  # Returns the selected object from a select_pane and defines
  # the selected? method on it to return true (so that define_selected
  # will work properly
  #
  def find_selected(name)
    array = instantiate_array_from_hashes(@params[name])
    selected = @params["#{name}_selected"]
    selected_object = array.find { |o| o.class.name == selected }
    unless selected_object
      Log.error "No selected object among '#{name}'"
      Log.error "params: #{@params[name].inspect}"
      Log.error "array: #{array.inspect}"
      Log.error "selected: #{selected}"
      raise "No selected object found. See log for details."
    end
    def selected_object.selected?
      true
    end
    selected_object
  end
    
protected

  # Override so we can get rid of the Content-Disposition
  # headers by specifying :no_disposition => true in options
  # This is needed when we want to send big files that are
  # *not* intended to pop up a save-as dialog in the browser,
  # such as content to display in iframes (logs and files)
  def send_file_headers!(options)
    options.update(DEFAULT_SEND_FILE_OPTIONS.merge(options))
    [:length, :type, :disposition].each do |arg|
      raise ArgumentError, ":#{arg} option required" if options[arg].nil?
    end

    headers = {
      'Content-Length'            => options[:length],
      'Content-Type'              => options[:type]
    }
    unless(options[:no_disposition])
      disposition = options[:disposition].dup || 'attachment'
      disposition <<= %(; filename="#{options[:filename]}") if options[:filename]
      headers.merge!(
        'Content-Disposition'       => disposition,
        'Content-Transfer-Encoding' => 'binary'
      )
    end
        
    @headers.update(headers);
  end

end

module ActionView

  class Base
    include Inflector

    def breadcrumbs
      link_to_unless_current("Dashboard", :controller => "project", :action => "index")
    end

    # Renders plain text (if +input+ is true) or a text field if not.
    def text_or_input(input, options)
      if(input)
        options[:class] = "setting-input" unless options[:class]
        tag("input", options)
      elsif(:type == "password")
        "********"
      elsif(options[:value] =~ /^http?:\/\//)
        content_tag("a", options[:value], :href => options[:value] ? options[:value] : "")
      else
        options[:value] ? content_tag("span", options[:value], :id => options[:name]) : ""
      end
    end

    # Renders an editable or read-only element describing a boolean value.
    #
    # Options:
    # * <tt>:name</tt> - The name of the variable/attribute.
    # * <tt>:value</tt> - True or False
    # * <tt>:editable</tt> - True or False
    def text_or_checkbox(options)
      value = options.delete(:value)
      if(options.delete(:editable))
        options[:type] = "checkbox"
        options[:value] = "true"
        options[:checked] = "true" if value
        tag("input", options)
      else
        value ? "on" : "off"
      end
    end
    
    def text_or_select(input, options)
      values = options.delete(:values)
      if(input)
        #options[:class] = "setting-input" unless options[:class]
        
        option_tags = "\n"
        values.each do |value|
          option_attrs = {:value => value.class.name}
          option_attrs[:selected] = "selected" if value.selected?
          option_tag = content_tag("option", value.name, option_attrs)
          option_tags << option_tag << "\n"
        end
        content_tag("select", option_tags, options)
      else
        values.find {|v| v.selected?}.name
      end
    end
    
    # Renders a tab pane where each tab contains rendered objects
    def tab_pane(name, array)
      define_selected!(array)
      $pane_name = name
      def array.name
        $pane_name
      end
      render_partial("tab_pane", array)
    end

    # Renders a pane (div) with a combo (select) that will
    # Show one of the objects in the array (which are rendered with render_object).
    # If one of the objects in the array respond to selected? and return true,
    # it is preselected in the combo.
    def select_pane(description, name, array)
      define_selected!(array)
      $pane_name = name
      $pane_description = description
      def array.name
        $pane_name
      end
      def array.description
        $pane_description
      end
      render_partial("select_pane", array)
    end

    # defines selected? => false on each object that doesn't already have selected? defined.
    def define_selected!(array)
      array.each do |o|
        unless(o.respond_to?(:selected?))
          def o.selected?
            false
          end
        end
      end
    end

    # Creates a table rendering +o+'s attributes.
    # Uses a default rendering, but a custom template
    # will be used if there is a "_<underscored_class_name>.rhtml"
    # under the project directory
    def render_object(o, collection_name, edit)
      underscored_name = underscore(demodulize(o.class.name))
      template = File.expand_path(File.dirname(__FILE__) + "/../views/project/_#{underscored_name}.rhtml")
      if(File.exist?(template))
        render_partial(underscored_name, o)
      else
        r = "<table>\n"
        o.__attr_accessors.each do |attr_name|
          attr_anns = o.class.send(attr_name[1..-1])
          if(attr_anns && attr_anns[:description])
            # Only render attributes with :description annotations
            attr_value = o.instance_variable_get(attr_name)
            r << "  <tr>\n"
            r << "    <td width='25%'>#{attr_anns[:description]}</td>\n"
            html_value = text_or_input(edit, :name => "#{collection_name}[#{o.class.name}][#{attr_name}]", :value => attr_value)
            r << "    <td width='75%'>#{html_value}</td>\n"
            r << "  </tr>\n"
          end
        end
        # workaround for RoR bug. 'hash' form params must have at least one value.
        r << "<tr><td></td><td><input type='hidden' name='#{collection_name}[#{o.class.name}][__dummy]' /></td></tr>" if o.instance_variables.empty?

        r << "</table>"
        r
      end
    end

    # Creates an image with a tooltip that will show on mouseover.
    #
    # Options:
    # * <tt>:txt</tt> - The text to put in the tooltip. Can be HTML.
    # * <tt>:img</tt> - The image to display on the page. Defaults to '/images/16x16/about.png'
    def tip(options)
      tip = options.delete(:txt)
      options[:src] = options.delete(:img) || "/images/16x16/about.png"
      options[:onmouseover] = "Tooltip.show(event,#{tip})"
      options[:onmouseout] = "Tooltip.hide()"
      options[:alt] = " "

      tag("img", options)
    end
    
    # Renders a Calendar widget
    # The view (or layout) must load the jscalendar and dateFormat javascripts
    # Note that the value is posted back as a ymdHMS string
    #
    # * <tt>:name</tt> - The name of the (hidden) field containing the date
    # * <tt>:time</tt> - The time to initialise the widget with
    # * <tt>:editable</tt> - Whether or not to make the widget editable
    def calendar(options)
      t = options[:time]
      name = options[:name]
      js_function = "change" + name.gsub(/:/, '_').gsub(/@/, '_').gsub(/\[/, '_').gsub(/\]/, '_')
      js_format = "format('%yyyy%%mm%%dd%%hh%%nn%%ss%')"
      js_date = "new Date(#{t.year}, #{t.month - 1}, #{t.day}, #{t.hour}, #{t.min}, #{t.sec})"
      <<EOF
<input type="hidden" id="#{options[:name]}" name="#{options[:name]}" value="" />
<div id="#{options[:name]}_calendar"></div>
<script type="text/javascript">
<!--
  document.getElementById('#{options[:name]}').value = #{js_date}.#{js_format}
  function #{js_function}(calendar) {    
    if (calendar.dateClicked) {      
      document.getElementById('#{options[:name]}').value = calendar.date.#{js_format};
    }  
  };  
  
  Calendar.setup( {
    flat         : "#{options[:name]}_calendar", // ID of the parent element      
    flatCallback : #{js_function},           // our callback function
    showsTime    : true,
    date         : #{js_date}    
  });
-->
</script>
EOF
    end
  end
end
