// TODO: DEPRECATED
function showElement(selectedId, elementIds) {
  for(i = 0; i < elementIds.length; i++) {
    var id = elementIds[i];
    var style = "none";
    if(id == selectedId) {
      style = "block";
    }
    $(id).style.display = style;
  }
}

Settings = function(initial) {
  this.current = initial;

  this.show = function(element) {
    new Effect.Fade(this.current);
    new Effect.Appear(element);
    this.current = element;
  }
}