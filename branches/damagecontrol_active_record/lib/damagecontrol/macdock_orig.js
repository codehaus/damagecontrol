MacDock = function(parentId, id, items) {

  this.parentId = parentId;
  this.items = items;

  var parent = document.getElementById(parentId);

	if (typeof parent != "undefined") {
		div = appendElement(parent, "div");
		div.id = id;
		div.innerHTML = "";
		for(i in items) {
		  var item = items[i];
		  var inactive = item[0];
		  var active = item[1];
		  
		  var anchor = appendElement(div, "a");
		  var image = appendElement(anchor, "image");
		  image.active = active;
		  image.inactive = inactive;
		  image.current = image.active;
		  image.doit = item[2];

		  image.src = image.current;

      image.number = i;
      image.onmousemove = this.magnify;		  image.onclick = this.toggle;
      image.origWidth = image.width;      image.origHeight = image.height;      image.isDock = true;
      image.width = 24;
      image.height = 24;
		}
	}
}

MacDock.prototype.toggle = function (event) {
    img = event.target;
    img.current = (img.current == img.inactive ? img.active : img.inactive);
    img.src = img.current;
    eval(img.doit);
}

MacDock.prototype.magnify = function (event) {
  for(i in event.target) {
//    alert(event.target[i]);
  }
}



  appendElement = function (parent, type) {
  	var el = null;
	  if (document.createElementNS) {
  		// use the XHTML namespace; IE won't normally get here unless
	  	// _they_ "fix" the DOM2 implementation.
	  	el = document.createElementNS("http://www.w3.org/1999/xhtml", type);
	  } else {
		  el = document.createElement(type);
  	}
  	parent.appendChild(el);
  	return el;
  }


var dockImages = new Array();var dock;var doc_lock;var dock_image_over;var dock_mod_x = true;var dock_mod_y = true;var dock_stretch = 0.5; // this is the percentage of growthvar dock_profile = new Array();// use the dock_profile array to set up the bump shape.  The numbers should all add up to 1// and the first number should always be zero.  Each number represents the percentage drop in// size from the next one closer to the active icon.var dock_profiles = new Array();dock_profiles[0] = [0, 0.5, 0.3, 0.2];dock_profiles[1] = [0, 0.4, 0.3, 0.15, 0.10, 0.05];dock_profiles[2] = [0, 0.7, 0.2, 0.1];dock_profiles[3] = [0, 0.9, 0.05, 0.05];dock_profiles[4] = [0, 0.1, 0.15, 0.2, 0.4, 0.1, 0.05];dock_profile = dock_profiles[0];function prepDock(){
  dock_lock = false;  dock = document.getElementById('dock');  dock.onmouseout = restoreDock;  for (var i = 0; i < 12; i++)  {    name = 'img' + (i + 1);    dockImages[i] = document.getElementById(name);  }  for (var i = 0; i < dockImages.length; i++)  {    dockImages[i].origSrc = dockImages[i].src;    if (dockImages[i].getAttribute('onsrc'))    {      dockImages[i].onImage = new Image();      dockImages[i].onImage.src = dockImages[i].getAttribute('onsrc');    }    dockImages[i].number = i;    dockImages[i].onmousemove = magnify;    dockImages[i].origWidth = dockImages[i].width;    dockImages[i].origHeight = dockImages[i].height;    dockImages[i].isDock = true;  }}function restoreDock(event){  if (dock_lock) return false;//  if (window.event) event = window.event;//  if (!event.toElement) return false;//  if (event.toElement.isDock) return false;  for (i = 0; i < dockImages.length; i++)  {    img = dockImages[i];    img.src = img.origSrc;    img.width = img.origWidth;    img.height = img.origHeight;  } }function restoreDockSmooth(c){  // this function is not used since it's a little buggy still.  steps = 3;  if (!c) c = 0;  if (dock_lock && (c == 0)) return false;  dock_lock = true;  if (c == steps)  {      for (i = 0; i < dockImages.length; i++)    {      dockImages[i].width = dockImages[i].origWidth;      dockImages[i].height = dockImages[i].origHeight;    }         dock_lock = false;    return false;  }  else  {    for (i = 0; i < dockImages.length; i++)    {      dockImages[i].width = (dockImages[i].origWidth * c + dockImages[i].width * (steps - c)) / steps;      dockImages[i].height = (dockImages[i].origHeight * c + dockImages[i].height * (steps - c)) / steps;    }       }    c++;  setTimeout('restoreDockSmooth(' + c + ')', 10);}function magnify(event){
  var img = event.target;  if (dock_lock) return false;  dock_lock = true;  dock_image_over = img;  if (img.onImage)    img.src = img.onImage.src;
  // restore all icons we're NOT looking at  for (var i = 0; i < dockImages.length; i++)  {    // ignore those within two of the selected icon    if ((i - img.number > 3) || (i - img.number < -3))    {      dockImages[i].src = dockImages[i].origSrc;      dockImages[i].width = dockImages[i].origWidth;      dockImages[i].height = dockImages[i].origHeight;    }  }  max = 1 + dock_stretch;    // resize the icon we are hovering over;  if (dock_mod_x) img.width = img.origWidth * max;  if (dock_mod_y) img.height = img.origHeight * max;    event.cancelBubble = true;    // this is the distance from the left edge, in %
  var offsetX = event.offsetX ? event.offsetX : event.pageX - findPosX(img);  percentage = offsetX / img.width;    if (percentage > 1) percentage = 1;  i_percentage = 1 - percentage;  //window.status = 'percentage: ' + percentage + ', i_percentage: ' + percentage;  i = img.number;  // update the 3 to the left  max = 1 + dock_stretch;    for (j = 1; j < dock_profile.length; j++)  {    img = dockImages[i - j];    max -= dock_stretch * dock_profile[j - 1];    range = dock_profile[j] * dock_stretch;      if (img)    {      img.src = img.origSrc;      if (dock_mod_x) img.width = Math.floor(img.origWidth * (max - percentage * range));      if (dock_mod_y) img.height = Math.floor(img.origHeight * (max - percentage * range));    }  }  // update the 3 to the right  max = 1 + dock_stretch;    for (j = 1; j < dock_profile.length; j++)  {    img = dockImages[i + j];        max -= dock_stretch * dock_profile[j - 1];    range = dock_profile[j] * dock_stretch;      if (img)    {      img.src = img.origSrc;      if (dock_mod_x) img.width = Math.floor(img.origWidth * (max - i_percentage * range));      if (dock_mod_y) img.height = Math.floor(img.origHeight * (max - i_percentage * range));    }  }

  // set caption
//  var capt = document.getElementById('caption');
//  capt.style = "position:absolute;left:" + event.pageX + ";top:250;";
  dock_lock = false;}function mouseX(e){	var posx = 0;	if (!e) var e = window.event;	if (e.pageX || e.pageY)		posx = e.pageX;	else if (e.clientX || e.clientY)		posx = e.clientX + document.body.scrollLeft;  return posx;}

// http://www.quirksmode.org/js/findpos.htmlfunction findPosX(obj){	var curleft = 0;	if (obj.offsetParent)	{		while (obj.offsetParent)		{			curleft += obj.offsetLeft			obj = obj.offsetParent;		}	}	else if (obj.x)		curleft += obj.x;	return curleft;}