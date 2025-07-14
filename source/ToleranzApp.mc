import Toybox.Application;
import Toybox.Lang;
import Toybox.Sensor;
import Toybox.SensorHistory;
import Toybox.System;
import Toybox.Time;
import Toybox.WatchUi;

class ToleranzApp extends Application.AppBase {
  private var _state as ToleranzState;

  function initialize() {
    self._state = new ToleranzState();

    AppBase.initialize();
  }

  // onStart() is called on application start up
  function onStart(state as Dictionary?) as Void {}

  // onStop() is called when your application is exiting
  function onStop(state as Dictionary?) as Void {
    _state.destroy();
  }

  // Return the initial view of your application here
  function getInitialView() as [Views] or [Views, InputDelegates] {
    if (_state.getStatus().hasError()) {
      return [new ToleranzInfoView(_state)];
    } else {
      return [new ToleranzView(_state), new ToleranzDelegate(_state)];
    }
  }
}

function getApp() as ToleranzApp {
  return Application.getApp() as ToleranzApp;
}
