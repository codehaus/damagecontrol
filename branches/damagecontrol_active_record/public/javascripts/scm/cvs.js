var Cvs = {
  with_port_regexp: new RegExp("^:([^:]*):(.*)@([^:]*):([0-9]*):([a-zA-Z]?.*)"),
  cvs_noport: new RegExp("^:([^:]*):(.*)@([^:]*):([a-zA-Z]?.*)"),
  local_regexp: new RegExp("^:(local):(.*)"),
  
  init: function() {
    var protocolIndex = 1;
    var userIndex     = -1;
    var serverIndex   = -1;
    var portIndex     = -1;
    var pathIndex     = -1;
    if(tokens = Cvs.with_port_regexp.exec($F('cvs_root'))) {
      userIndex = 2;
      serverIndex = 3;
      portIndex = 4;
      pathIndex = 5;
    } else if(tokens = Cvs.cvs_noport.exec($F('cvs_root'))) {
      userIndex = 2;
      serverIndex = 3;
      pathIndex = 4;
    } else if(tokens = Cvs.local_regexp.exec($F('cvs_root'))) {
      pathIndex = 2;
    }

    if(pathIndex != -1) {
      $('cvs_protocol').selectedIndex = Cvs.findIndex(tokens[protocolIndex])
      if(userIndex != -1) {
        $('cvs_user').value = tokens[userIndex];
        $('cvs_server').value = tokens[serverIndex];
      } else {
        Field.clear('cvs_user', 'cvs_user');
      }

      if(portIndex != -1) {
        $('cvs_port').value = tokens[portIndex];
      } else {
        Field.clear('cvs_port');
      }
      $('cvs_repodir').value = tokens[pathIndex];
    } else {
      // didn't match
      Cvs.clearFields();
      // TODO: make CVSROOT yellow and blank all the others. Also disable submit.
    }
    Cvs.enableOrDisableCvsFields();
  },

  clearFields: function() {
    $('cvs_protocol').selectedIndex = 0;
    Field.clear('cvs_user', 'cvs_user', 'cvs_port', 'cvs_repodir');
  },
  
  findIndex: function(protocol) {
    var arr = new Array("ext", "pserver", "local");
    for (var i=0; i < arr.length; i++) {
      if(arr[i] == protocol) {
        return i + 1;
      }
    }
    return 0;      
  },

  updateCvsRootField: function() {
    var userAtServerAtPort = "";
    if($F('cvs_protocol') != "local") {
      var port = $F('cvs_port') != "" ? $F('cvs_port') + ":" : "";
      userAtServerAtPort = $F('cvs_user') + "@" + $F('cvs_server') + ":" + port;
    }
    $('cvs_root').value = ":" + $F('cvs_protocol') + ":" + userAtServerAtPort + $F('cvs_repodir');
    Cvs.enableOrDisableCvsFields();
  },

  enableOrDisableCvsFields: function() {  
    if($F('cvs_protocol') == 'local') {
      $('cvs_password').disabled = true;
      $('cvs_user').disabled = true;
      $('cvs_server').disabled = true;
      $('cvs_port').disabled = true;
    } else if($F('cvs_protocol') == 'ext') {
      $('cvs_password').disabled = true;
      $('cvs_user').disabled = false;
      $('cvs_server').disabled = false;
      $('cvs_port').disabled = true;
    } else if($F('cvs_protocol') == 'pserver') {
      $('cvs_password').disabled = false;
      $('cvs_user').disabled = false;
      $('cvs_server').disabled = false;
      $('cvs_port').disabled = false;
    }
  },

  rules: {
    '.cvs_root'   : function(element) { element.onkeyup  = Cvs.init; },
    '.cvs_input'  : function(element) { element.onkeyup  = Cvs.updateCvsRootField; },
    '.cvs_select' : function(element) { element.onchange = Cvs.updateCvsRootField; },
  }
}
Cvs.init();
Behaviour.register(Cvs.rules);
