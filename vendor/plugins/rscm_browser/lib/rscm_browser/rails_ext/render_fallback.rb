# (Inspired from Tobias Luetke's Typo)
#
# Rails, by default, only looks for views in a single location, usually in app/views.
# However, we'd *really* like to be able to override views via themes, and that means
# adding something like a search path.  So here it is.

module ActionView
  class Base
    alias_method :__render_file, :render_file
    
    def render_file(template_path, use_full_path = true, local_assigns = {})
      search_path = [
        "../../vendor/plugins/rscm_browser/views",
        "."
      ]
      if use_full_path
        e = nil
        search_path.each do |prefix|
          theme_path = prefix+'/'+template_path
          begin
            return __render_file(theme_path, use_full_path, local_assigns)
          rescue ActionViewError => e
            next
          end
        end
        raise e
      else
        __render_file(template_path, use_full_path, local_assigns)
      end
    end
  end
end

module ActionController
  class Base
    alias_method :__render_file, :render_file
    
    def render_file(template_path, status = nil, use_full_path = false)
      search_path = [
        "../../vendor/plugins/rscm_browser/views",
        "."
      ]
      if use_full_path
        e = nil
        search_path.each do |prefix|
          theme_path = prefix+'/'+template_path
          begin
            return __render_file(theme_path, status, use_full_path)
          rescue MissingTemplate => e
            next
          end
        end
        raise e
      else
        return __render_file(template_path, status, use_full_path)
      end
    end
  end
end