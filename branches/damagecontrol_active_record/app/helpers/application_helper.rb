require 'damagecontrol'

module ApplicationHelper
  
  def field(object, name, attr_name, type="text", id=nil)
    tag("input", 
      :name => "#{name}[#{attr_name[1..-1]}]", 
      :value => object.instance_variable_get(attr_name).to_s,
      :type => type,
      :id => id
    )
  end

  def enabled_field(object)
    # We can't use field, since we want nil to be "false"
    tag("input", 
      :name => "#{object.category}[#{object.class.name}][enabled]", 
      :value => object.enabled ? "true" : "false",
      :type => "hidden",
      :id => object.enabled_id
    )
  end
  
  def file_system_link(artifact)
    link_to(
      File.basename(artifact.relative_path), 
      :controller => "file_system", :action => "browse", :params => {:path => artifact.relative_path.split('/')}
    ) + " (#{File.size(artifact.file) / 1024} Kb)"
  end
  
  def build_link(build)
    if(build.nil?)
      # Can't create a link to a nonexistant build! Just show a transparent image with same size as image links.
      image_tag("transparentpixel.gif", :border => 0, :size => "16x16")
    else
      link_to(
        image_tag(build.icon, :border => 0, :size => "16x16") + " " + build.state.class.name, 
        :controller => "build", :action => "show", :id => build.id
      )
    end
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
    check_box_tag("#{object.category}[#{object.class.name}][enabling_states][]", state_class_name, enabled, {:onclick => "publisherChanged('#{object.dom_id}');return true;", :id => nil})
  end
  
  # Tag that shows a tip icon. Must be closed with a </div> !
  def tip_box
    <<-EOT
    <div class="tip-box">
      #{image_tag("tip", :size => "48x48")}<br/>
    EOT
  end
end
