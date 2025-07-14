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

  function onBack() as Boolean {
    if (_state.isRunning()) {
      return true; // Ignore the back action
    } else {
      if (_state.getElapsedTime().greaterThan(new Time.Duration(0))) {
        _state.reset();
        return true;
      } else {
        return false; // Exit the app
      }
    }
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
