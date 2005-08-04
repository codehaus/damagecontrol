var categories = new Object();

/**
 * Manages panels on the settings screen.
 */
Settings = function(initial) {
  this.current = initial;

  /**
   * Fade currently showing element and make a new one (element) appear.
   */
  this.show = function(element, category, pluginId, exclusive) {
    var pluginIds = categories[category];
    if(exclusive) {
      for(i=0; i<pluginIds.length; i++) {
        var enabled = pluginIds[i]==pluginId;
        setImage(pluginIds[i], enabled);
        setEnabled(pluginIds[i], enabled);
      }
    }
    
    new Effect.Fade(this.current);
    new Effect.Appear(element);
    this.current = element;
  }
}

/**
 * Called when one of the enable checkboxes for a publisher is changed.
 */
function publisherChanged(publisherId) {
  setImage(publisherId, isEnabled(publisherId));
}

/**
 * Sets the enabled or disabled icon for both setting and menu.
 */
function setImage(pluginId, enabled) {
  var imageName = enabled ? pluginId + '_img_enabled' : pluginId + '_img_disabled';
  $(pluginId + '_img').src = eval(imageName).src;
  $(pluginId + '_img_menu').src = eval(imageName).src;
}

/**
 * Sets the value in the hidden 'enabled' field.
 */
function setEnabled(pluginId, enabled) {
  var enabledId = pluginId + '_enabled';
  $(enabledId).value = enabled;
}

/**
 * Returns true if the publisher is enabled for at least one of the build states
 */
function isEnabled(publisherId) {
  var enabling_state_checkboxes = $(publisherId).getElementsByTagName("input");
  for(i = 0; i < enabling_state_checkboxes.length; i++) {
    if(enabling_state_checkboxes[i].checked) {
      return true;
    }
  }
  return false;
}