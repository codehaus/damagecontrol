function setTab(tab) {
  stickyTab = tab
  showElement(stickyTab, tabs)
}

// hide all divs in the group unless selected
function showElement(selected, elements) {
//  alert("showElement(" + selected + ",[" + elements.join() + "])")
  for(element in elements) {
    id = elements[element]
//    alert("elements[" + element + "]=" + id)
    style = "none"
    if(id == selected) {
      style = "block"
    }
    document.getElementById(id).style.display = style
  }
}
