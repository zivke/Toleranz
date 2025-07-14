import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class ToleranzInfoView extends WatchUi.View {
  private var _state as ToleranzState;

  function initialize(state as ToleranzState) {
    self._state = state;

    View.initialize();
  }

  function onLayout(dc as Dc) as Void {}

  function onShow() as Void {}

  function onUpdate(dc as Dc) as Void {
    drawInfoMessage(dc, _state.getStatus().getMessage());
  }

  function onHide() as Void {}

  private function drawInfoMessage(
    dc as Graphics.Dc,
    message as String?
  ) as Void {
    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
    dc.clear();

    var infoMessage = new WatchUi.TextArea({
      :text => message != null ? message : "Unknown error",
      :backgroundColor => Graphics.COLOR_BLACK,
      :color => Graphics.COLOR_WHITE,
      :font => Graphics.FONT_TINY,
      :justification => Graphics.TEXT_JUSTIFY_CENTER |
      Graphics.TEXT_JUSTIFY_VCENTER,
      :locX => WatchUi.LAYOUT_HALIGN_CENTER,
      :locY => WatchUi.LAYOUT_VALIGN_CENTER,
      :width => dc.getWidth() * 0.8,
      :height => dc.getHeight() * 0.8,
    });
    infoMessage.draw(dc);
  }
}
