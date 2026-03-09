import Toybox.Lang;
import Toybox.WatchUi;

class ToleranzDelegate extends WatchUi.BehaviorDelegate {
  private var _state as ToleranzState;

  function initialize(state as ToleranzState) {
    self._state = state;

    BehaviorDelegate.initialize();
  }

  function onSelect() as Boolean {
    if (!_state.isRunning()) {
      _state.start();
    } else {
      _state.stop();
    }

    return true;
  }

  function onNextPage() as Boolean {
    _state.getSelector().up();

    return true;
  }

  function onPreviousPage() as Boolean {
    _state.getSelector().down();

    return true;
  }
}
