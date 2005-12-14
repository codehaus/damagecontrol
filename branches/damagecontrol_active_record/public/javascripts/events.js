Object.extend(Event, {
 trigger: function(element, name, canBubble, category) {
   element = $(element);
   if (element.fireEvent) {
     element.fireEvent('on' + name);
   } else {
     canBubble = (typeof(canBubble) == undefined) ? true : canBubble;
     var evt = document.createEvent(category);
     if(category == 'HTMLEvents') {
       evt.initEvent(name, canBubble, true);
     } else if(category == 'MouseEvents') {
       evt.initMouseEvent(name, canBubble, true, document.defaultView, 1, 0, 0, 0, 0, false, false, false, false, 0, null);
     }
     evt.initEvent(name, canBubble, true);
     element.dispatchEvent(evt);
   }
 }
});

Object.extend(Element, {
 click: function(element) {
   element = $(element);

   var pageUnloading = false;
   var pageUnloadDetector = function() {
     pageUnloading = true;
   };

   var wasChecked = element.checked;
   this.pageUnloading = false;
   window.attachEvent("onbeforeunload", pageUnloadDetector);
   Event.trigger(element, 'focus', false, 'HTMLEvents');
   element.click();
   try {
     window.detachEvent("onbeforeunload", pageUnloadDetector);
     if(window.closed) {
       return;
     }
     // Onchange event is not triggered automatically in IE.
     if (element.checked != undefined && wasChecked != element.checked) {
       Event.trigger(element, 'change', true, 'HTMLEvents');
     }
     Event.trigger(element, 'blur', true, 'HTMLEvents');
   } catch (e) {
     // If the page is unloading, we may get a "Permission denied" or "Unspecified error".
     // Just ignore it, because the document may have unloaded.
     if(pageUnloading) {
       return;
     }
     throw e;
   }
 }
});

var runTests = function() {
 alert(document.cookie);
 $('q').value="aslak";
 Element.click('btnG');
}

if (typeof window.onload != 'function') {
 window.onload = runTests;
} else {
 var oldonload = window.onload;
 window.onload = function() {
   oldonload();
   runTests();
 }
}