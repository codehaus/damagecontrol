module ProjectHelper
  def test_publisher_link(text, object, build_state, update_id)
    link_to_remote(
      text,
      {
        :submit => "project_settings",
        :url => {
          :controller => "project", 
          :action => "test_publisher", 
          :params => {
            :publisher_class_name => object.class.name,
            :build_state_class_name => build_state.class.name
          }
        },
        :update => update_id,
        :complete => "Effect.Pulsate('#{update_id}')"
      }
    ) 
  end
end
