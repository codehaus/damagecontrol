function setTab(tab) {
  stickyTab = tab
  showElement(stickyTab, tabs)
}

function showElement(selected, elements) {
  // hide all divs in the group unless selected
  for(element in elements) {
    id = elements[element]
    style = "none"
    if(id == selected) {
      style = "block"
    }
    document.getElementById(id).style.display = style
  }
}
