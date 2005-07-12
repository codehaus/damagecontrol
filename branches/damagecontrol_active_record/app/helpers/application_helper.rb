# The methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  
  def field(object, name, attr_name)
    tag("input", :name => "#{name}[#{attr_name[1..-1]}]", :value => object.instance_variable_get(attr_name))
  end
  
  def description(clazz, attr_name)
    attr_name[1..-1]
  end

  def render_object(object_name)
    object = instance_variable_get("@#{object_name}") 
    render :partial => 'shared/object', 
           :locals => {:object => object, :object_name => object_name}
  end

  def render_object_with_name(object, name)
    render :partial => 'shared/object', 
           :locals => {:object => object, :object_name => name}
  end

  def tab_link(text, image, element_id, element_group)
    content_tag("a", 
                image_tag(image) << text, 
                :href => "#", :onclick => "javascript:showElement('#{element_id}', #{element_group});")
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
    render :partial => 'shared/calendar', 
           :locals => {:js_function => js_function, :js_format => js_format, :js_date => js_date, :options => options}
  end
  
  # Renders a pane (div) with a combo (select) that will
  # Show one of the objects in the array (which are rendered with render_object).
  # If one of the objects in the array respond to selected? and return true,
  # it is preselected in the combo.
  def select_pane(objects_name, selected)
    objects = instance_variable_get("@#{objects_name}") 
    render :partial => 'shared/select_pane', 
           :locals => {:objects_name => objects_name, :objects => objects, :selected => selected}
  end

end


