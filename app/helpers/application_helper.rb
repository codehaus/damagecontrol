require 'damagecontrol'

module ActionView
  module Helpers
    class FormBuilder
      def exclusive?
        @object.is_a?(RSCM::Base)
      end

      def render(binding)
        @template.render(
          :partial => 'shared/object', 
          :locals => {:object => @object, :prefix => prefix, :default_render_excludes => default_render_excludes}
        )
      end

      def default_render_excludes
        @object.respond_to?(:default_render_excludes) ? 
          @object.default_render_excludes :
          [:enabled, :fileutils_label, :fileutils_output, :content_type, :uses_polling, :enabling_states, :revision_detection]
      end

      def group_name
        return 'scm' if @object.is_a?(RSCM::Base)
        return 'tracker' if @object.is_a?(MetaProject::Tracker::Base)
        return 'publisher' if @object.is_a?(DamageControl::Publisher::Base)
        return 'general'
      end

      def prefix
        return 'scm_web' if @object.is_a?(MetaProject::ScmWeb::Browser)
        return 'project' if @object.is_a?(Project)
        return "#{group_name}[#{@object.class.name}]"
      end
      
      def icon
        @object.enabled ? enabled_icon : disabled_icon
      end

      def enabled_icon
        "#{underscore}.png"
      end

      def disabled_icon
        "#{underscore}_grey.png"
      end

      def enabled_js_var
        "#{domify}_enabled_img"
      end

      def disabled_js_var
        "#{domify}_disabled_img"
      end

      def img_id
        "#{domify}_img"
      end

      def content_id
        "#{domify}_content"
      end
      
      def plugin_path
        "plugin/#{underscore}"
      end
      
      # Creates a hidden field that indicates whether a plugin is enabled or not.
      # The value of this field is updated via Javascript as a response to UI events.
      def enabled_field
        @template.tag("input", 
          :name => "#{prefix}[enabled]", 
          :value => @object.enabled ? "true" : "false",
          :type => 'hidden',
          :id => enabled_field_id
        )
      end
      
      def enabled_field_id
        "#{domify}_enabled"
      end

      # Checkbox tag for publishers' enabling states
      def enabling_state_tag(state_class_name)
        enabled = @object.enabling_states && !@object.enabling_states.find{|state| state.class.name == state_class_name}.nil?
        @template.check_box_tag("#{prefix}[enabling_states][]", state_class_name, enabled, {:onchange => "damageControlPlugins.enable('#{@object.class.name}', this);return true;", :id => nil})
      end

      def visual_name
        @object.class.name.demodulize
      end

      def domify
        underscore.gsub(/\//, '_')
      end
      
      def underscore
        @object.class.name.underscore
      end      
    end
  end
end

module ApplicationHelper

  # Works like link_to_remote, but makes the link toggle after first fetch.
  # IMPORTANT: each use per page must use different +update+ parameters.
  # TODO: we could generate random ids for anchors.. 
  def toggle_link_to_remote(content, update, controller, action, id)
    anchor_id = "#{update}_link"
    link_to_remote(
      content, {
        :update => update,
        :url => {
          :controller => controller, 
          :action => action, 
          :id => id
        },
          :complete => "$('#{anchor_id}').onclick = function(){Element.toggle('#{update}')}"
      }, {
        :id => anchor_id
      }
    )
  end
  
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
  
  def description(clazz, attr_name)
    attr_name[1..-1]
  end
  
  def has_template(dir, name)
    template_file = File.expand_path("#{RAILS_ROOT}/app/views/#{dir}/_#{name}.rhtml")
    File.exist?(template_file)
  end

  def template_for(dir, name)
    template_name = "#{dir}/#{name}"
  end
    
  # Tag that shows a tip icon. Must be closed with a </div> !
  def tip_box
    <<-EOT
    <div class="tip-box">
      #{image_tag("tip", :size => "48x48")}<br/>
    EOT
  end
  
  def build_inline_link(build)
    render :partial => "build/inline_link", :locals => {:build => build}
  end

  def revision_inline_link(revision)
    render :partial => "revision/inline_link", :locals => {:revision => revision}
  end
  
end
