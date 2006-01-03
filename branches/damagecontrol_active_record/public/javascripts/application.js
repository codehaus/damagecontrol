// Similar to Rails' Inflector
String.prototype.underscore = function() {
  return this.replace(/::/g, '/').replace(/([A-Z]+)([A-Z][a-z])/g,'$1_$2').replace(/([a-z,0-9])([A-Z])/g,'$1_$2').toLowerCase();
}
String.prototype.underscoreFully = function() {
  return this.underscore().replace(/\//g, '_');
}
String.prototype.contentElement = function() {
  return this.underscoreFully() + '_content';
}
String.prototype.imgElement = function() {
  return this.underscoreFully() + '_img';
}
String.prototype.enabledElement = function() {
  return this.underscoreFully() + '_enabled';
}

var DamageControl = {};

/**
 * Facade for displaying plugin details.
 */
DamageControl.Plugins = Class.create();
DamageControl.Plugins.prototype = {
  pluginGroups: {},
  plugins: {},
  
  initialize: function(imageRoot) {
    this.imageRoot = imageRoot;
  },

  /**
   * Adds a new plugin for +className+
   */
  add: function(groupName, className, exclusive) {
    var pluginGroup = this.pluginGroups[groupName];
    if(pluginGroup == undefined) {
      this.pluginGroups[groupName] = pluginGroup = new DamageControl.PluginGroup(this, groupName, exclusive);
    }
    var plugin = new DamageControl.Plugin(pluginGroup, className, this.imageRoot);
    pluginGroup.add(plugin);
    this.plugins[className] = plugin;
  },

  show: function(className) {
    if(this.showingClassName != undefined) {
      Element.hide(this.showingClassName.contentElement());
    }
    this.showingClassName = className;
    Element.show(this.showingClassName.contentElement());

    this.plugins[className].shown();
  },

  /**
   * Called for plugins that have checkboxes, i.e. non-exclusive ones.
   */
  enable: function(className, e) {
    var checked = false;
    $A($(className.contentElement()).getElementsByTagName("input")).each(function(element) {
      if(element.checked) {
        checked = true;
      }
    });
    damageControlPlugins.plugins[className].setEnabled(checked, false);
  }
}

/**
 * Keeps track of a group of plugins, such as scm, tracker or other.
 * Knows whether or not its plugins are exclusive. An exclusive PluginGroup
 * will display the enabled image when a plugin is shown, and show the disabled
 * image for the other plugins in the same group.
 */
DamageControl.PluginGroup = Class.create();
DamageControl.PluginGroup.prototype = {
  initialize: function(plugins, groupName, exclusive) {
    this.plugins = [];
    this.plugins = plugins;
    this.groupName = groupName;
    this.exclusive = exclusive;
  },
  
  add: function(plugin) {
    this.plugins[0] = (plugin);
  },
  
  shown: function(plugin) {
    if(this.exclusive) {
      if(this.enabledPlugin != undefined) {
        this.enabledPlugin.setEnabled(false, true);
      }
      plugin.setEnabled(true, true);
      this.enabledPlugin = plugin;
    }
  }  
}

DamageControl.Plugin = Class.create();
DamageControl.Plugin.prototype = {
  initialize: function(pluginGroup, className, imageRoot) {
    this.pluginGroup = pluginGroup;
    this.className = className;
    this.enabledImg = new Image();
    this.enabledImg.src = imageRoot + '/' + className.underscore() + '.png';
    if(pluginGroup.groupName != 'general') {
      this.disabledImg = new Image();
      this.disabledImg.src = imageRoot + '/' + className.underscore() +'_grey.png';
    }
  },
  
  shown: function() {
    this.pluginGroup.shown(this);
  },

  setEnabled: function(enabled, updateEnabledElement) {
    $(this.className.imgElement()).src = enabled ? this.enabledImg.src : this.disabledImg.src;
    if(updateEnabledElement) {
      $(this.className.enabledElement()).value = enabled;
    }
  }
}
