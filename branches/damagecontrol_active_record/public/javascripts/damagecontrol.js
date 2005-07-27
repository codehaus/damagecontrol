/**
 * Manages panels on the settings screen.
 */
Settings = function(initial) {
  this.current = initial;

  /**
   * Fade currently showing element and make new one appear.
   */
  this.show = function(element) {
    new Effect.Fade(this.current);
    new Effect.Appear(element);
    this.current = element;
  }
}
