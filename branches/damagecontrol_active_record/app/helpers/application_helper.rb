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

    table_template = <<-EOS
<table>
  <tbody>
    <% object.to_yaml_properties.each do |attr_name| %>
    <tr>
      <td><%= description(object.class, attr_name) %></td>
      <td><%= field(object, object_name, attr_name) %></td>
    </tr>
    <% end %>
  </tbody>
</table>
EOS

    render :inline => table_template, :locals => { :object => object, :object_name => object_name }
  end
end


