require_dependency 'damagecontrol'
require_dependency 'build'

module ApplicationHelper
  
  def field(object, name, attr_name, type="text", id=nil)
    tag("input", 
      :name => "#{name}[#{attr_name[1..-1]}]", 
      :value => object.instance_variable_get(attr_name),
      :type => type,
      :id => id
    )
  end

  def artifact_link(artifact)
    link_to(
      File.basename(artifact.relative_path), 
      :controller => "file_system", :action => "artifacts", :params => {:path => artifact.relative_path.split('/')}
    )
  end
  
  def enabled_field(object)
    field(object, "#{object.category}[#{object.class.name}]", "@enabled", "hidden", object.enabled_id)
    # <input id="<%= object.enabled_id %>" name="scm[<%= object.class.name %>][enabled]" value="<%= object.enabled %>">
  end
  
  def description(clazz, attr_name)
    attr_name[1..-1]
  end

  # Renders +object+'s attributes as form fields in a table. Each field's name
  # will be prefixed by +prefix+. If +object+ responds to a method named 'default_render_excludes'
  # that returns an array, the attributes matching the symbols in this array will 
  # be omitted from rendering.
  def render_object(object, prefix)
    default_render_excludes = object.respond_to?(:default_render_excludes) ? object.default_render_excludes : []
    render :partial => 'shared/object', 
           :locals => {:object => object, :prefix => prefix, :default_render_excludes => default_render_excludes}
  end

  def has_template(category, name)
    template_file = File.expand_path(RAILS_ROOT + 
      "/app/views/#{category}/_#{name}.rhtml")
    File.exist?(template_file)
  end
  
  def template_for(category, name)
    template_name = "#{category}/#{name}"
  end
  
  # Checkbox tag for publishers' enabling states
  def enabling_state_tag(object, state_class_name)
    enabled = object.enabling_states && !object.enabling_states.find{|state| state.class.name == state_class_name}.nil?
    check_box_tag("#{object.category}[#{object.class.name}][enabling_states][]", state_class_name, enabled, {:onchange => "publisherChanged('#{object.dom_id}');return false;", :id => nil})
  end
  
  # Tag that shows a tip icon. Must be closed with a </div> !
  def tip_box
    <<-EOT
    <div class="tip-box">
      #{image_tag("atom", :size => "24x24")} Tip!<br/>
    EOT
  end
end
