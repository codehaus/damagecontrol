cvs_port   = new RegExp("^:([^:]*):(.*)@([^:]*):([0-9]*):([a-zA-Z]?.*)")
cvs_noport = new RegExp("^:([^:]*):(.*)@([^:]*):([a-zA-Z]?.*)")
cvs_local  = new RegExp("^:(local):(.*)")

function distributeCvsrootFields() {
	cvsroot = document.getElementById('cvsroot').value

	protocolIndex = 1
	userIndex     = -1
	serverIndex   = -1
	portIndex     = -1
	pathIndex     = -1
	if(tokens = cvs_port.exec(cvsroot)) {
		userIndex = 2
		serverIndex = 3
		portIndex = 4
		pathIndex = 5
	} else if(tokens = cvs_noport.exec(cvsroot)) {
		userIndex = 2
		serverIndex = 3
		pathIndex = 4
	} else if(tokens = cvs_local.exec(cvsroot)) {
		pathIndex = 2
	}
	if(pathIndex != -1) {
		document.getElementById('cvsprotocol').selectedIndex = findIndex(tokens[protocolIndex])

		if(userIndex != -1) {
			document.getElementById('cvsuser').value = tokens[userIndex]
			document.getElementById('cvsserver').value = tokens[serverIndex]
		} else {
			document.getElementById('cvsuser').value = ""
			document.getElementById('cvsserver').value = ""
		}

		if(portIndex != -1) {
			document.getElementById('cvsport').value = tokens[portIndex]
		} else {
			document.getElementById('cvsport').value = ""
		}

		document.getElementById('cvsrepodir').value = tokens[pathIndex]
	} else {
		// didn't match
		clearCvsFields()
		// TODO: make CVSROOT yellow and blank all the others. Also disable submit.
	}
	enableOrDisableCvsFields()
}

function clearCvsFields() {
	document.getElementById('cvsprotocol').selectedIndex = 0
	document.getElementById('cvsuser').value = ""
	document.getElementById('cvsserver').value = ""
	document.getElementById('cvsport').value = ""
	document.getElementById('cvsrepodir').value = ""
}

function findIndex(protocol) {
	arr = new Array("ext", "pserver", "local")
	for (var i=0; i < arr.length; i++) {
		if(arr[i] == protocol) {
			return i + 1
		}
	}
	return 0
}

function updateCvsRootField() {
	userAtServerAtPort = ""
	if(document.getElementById('cvsprotocol').value != "local") {
		// it's proper client/server
		port = document.getElementById('cvsport').value != "" ? document.getElementById('cvsport').value + ":" : ""
		userAtServerAtPort =
			document.getElementById('cvsuser').value + "@" +
			document.getElementById('cvsserver').value + ":" +
			port
	}
	document.getElementById('cvsroot').value = ":" +
		document.getElementById('cvsprotocol').value + ":" +
		userAtServerAtPort +
		document.getElementById('cvsrepodir').value
	enableOrDisableCvsFields()
}

function enableOrDisableCvsFields() {
	if(document.getElementById('cvsprotocol').value == "local") {
		document.getElementById('cvsuser').disabled = true
		document.getElementById('cvspassword').disabled = true
		document.getElementById('cvsserver').disabled = true
		document.getElementById('cvsport').disabled = true
	} else if(document.getElementById('cvsprotocol').value == "ext") {
		document.getElementById('cvsuser').disabled = false
		document.getElementById('cvspassword').disabled = true
		document.getElementById('cvsserver').disabled = false
		document.getElementById('cvsport').disabled = false
	} else if(document.getElementById('cvsprotocol').value == "pserver") {
		document.getElementById('cvsuser').disabled = false
		document.getElementById('cvspassword').disabled = false
		document.getElementById('cvsserver').disabled = false
		document.getElementById('cvsport').disabled = false
	}
}
