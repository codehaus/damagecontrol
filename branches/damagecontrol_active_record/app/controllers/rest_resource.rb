# Taken from http://www.xml.com/pub/a/2005/11/02/rest-on-rails.html
module RestResource
  def self.append_features(base)
    super
    base.extend(ClassMethods)
  end

  module ClassMethods
    # TODO: deal with pseudo-relationships (YAML'ed fields) or maybe use YAML
    # altogether? (But this will complicate clients)
    def rest_resource_xml(model_id, options = {})
      singular_name = model_id.to_s
      class_name    = options[:class_name] || singular_name.camelize
      plural_name   = singular_name.pluralize
      suffix        = options[:suffix] ? "_#{singular_name}" : ""
      
      module_eval <<-"end_eval",__FILE__,__LINE__
        def #{singular_name}_xml
          require 'rexml/document'
          template = <<-end_template
xml.tag!(@obj.class.to_s.downcase,{:id => @obj.id}) {
  @obj.class.content_columns.each { |col|
    xml.tag!(col.name,@obj[col.name])
  }
  @obj.class.reflect_on_all_associations.each { |assoc|
    if assoc.macro == :belongs_to || assoc.macro == :has_one
      rels = [@obj.method(assoc.name).call]
    end
    if assoc.macro == :has_many || assoc.macro == :has_and_belongs_to_many
      rels = @obj.method(assoc.name).call
    end
    rels.each { |rel|
      if rel
        name = rel.class.to_s.downcase
        xml.tag!(name,{:id=>rel.id, :href =>url_for(:only_path=>false,:action => name+"_xml",:id=>rel.id)})
      end
    }
  }
}
end_template
          if request.post?
            xml = REXML::Document.new(request.raw_post)
            @data = {}
            xml.elements.each("/#{singular_name}/*") { |elt| 
              @data[elt.name] = elt.text
            }
            if params[:id]
              @obj = #{class_name}.update(params[:id],@data)
              render(:inline=>template,:type => :rxml,:layout=>false)
            else
              @obj = #{class_name}.create(@data)
              response.headers['Location'] = url_for(:action => '#{singular_name}_xml', :id => @obj)
              return render(:text => "", :status => 201)
            end
          end
          if request.get?
            @obj = #{class_name}.find(params[:id])
            render(:inline=>template,:type => :rxml,:layout=>false)
          end
          if request.delete?
            @obj = #{class_name}.find(params[:id])
            @obj.destroy()
            return render(:text => "", :status => 204)
          end
        end
      end_eval
    end
  end
end
