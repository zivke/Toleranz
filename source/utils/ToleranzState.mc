import Toybox.Activity;
import Toybox.ActivityMonitor;
import Toybox.Attention;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.Timer;
import Toybox.WatchUi;

class Status {
  enum Code {
    UNKNOWN_ERROR = -6,
    UNSUPPORTED = -5,
    INVALID_DATA = -4,
    HEART_RATE_HISTORY_NOT_SUPPORTED = -3,
    TEMPERATURE_HISTORY_NOT_SUPPORTED = -2,
    SENSOR_HISTORY_NOT_SUPPORTED = -1,
    INITIALIZING = 0,
    INITIALIZED = 1,
    RUNNING = 2,
    STOPPED = 3,
  }

  private var _code as Code = INITIALIZING;

  function getCode() as Code {
    return _code;
  }

  function setCode(code as Code) {
    self._code = code;
    WatchUi.requestUpdate();
  }

  function hasError() as Boolean {
    return _code < 0;
  }

  function getMessage() as String {
    var message = "";
    if (_code < 0) {
      message = "Error: ";
    }

    switch (self._code) {
      case UNKNOWN_ERROR:
        message += "Unknown";
        break;
      case HEART_RATE_HISTORY_NOT_SUPPORTED:
        message += "Heart rate history not supported";
        break;
      case TEMPERATURE_HISTORY_NOT_SUPPORTED:
        message += "Temperature history not supported";
        break;
      case SENSOR_HISTORY_NOT_SUPPORTED:
        message += "Sensor history not supported";
        break;
      case INITIALIZING:
        message += "Initializing...";
        break;
      case INITIALIZED:
        message += "Initialized";
        break;
      case RUNNING:
        message += "Running...";
        break;
      case STOPPED:
        message += "Stopped";
        break;
      default: {
        message += "Status unknown";
        break;
      }
    }

    return message;
  }
}

class Selector {
  enum Type {
    HEART_RATE,
    TEMPERATURE,
  }

  private var _type as Type = HEART_RATE;

  function getType() as Type {
    return _type;
  }

  function up() as Void {
    switch (_type) {
      case HEART_RATE:
        _type = TEMPERATURE;
        break;
      case TEMPERATURE:
        _type = HEART_RATE;
        break;
    }
    WatchUi.requestUpdate();
  }

  function down() as Void {
    up();
  }
}

class ToleranzState {
  // Fetch the system units
  private var _systemUnits as System.UnitsSystem;

  private var _status as Status;
  private var _selector as Selector;

  private var _startTime as Time.Moment?;
  private var _elapsedTime as Time.Duration;

  private var _timer as Timer.Timer;

  private var _heartRateData as ToleranzData?;
  private var _temperatureData as ToleranzData?;

  function initialize() {
    self._systemUnits = System.getDeviceSettings().temperatureUnits;
    self._status = new Status();
    self._selector = new Selector();
    self._elapsedTime = new Time.Duration(0);
    self._timer = new Timer.Timer();
    self._heartRateData = new ToleranzData(null);

    // Check device for SensorHistory compatibility
    if (!(Toybox has :SensorHistory)) {
      self._status.setCode(Status.SENSOR_HISTORY_NOT_SUPPORTED);
    }

    if (!(Toybox.SensorHistory has :getTemperatureHistory)) {
      self._status.setCode(Status.TEMPERATURE_HISTORY_NOT_SUPPORTED);
    }

    // Check device for SensorHistory compatibility
    if (!(Toybox.SensorHistory has :getHeartRateHistory)) {
      self._status.setCode(Status.HEART_RATE_HISTORY_NOT_SUPPORTED);
    }

    self._timer.start(method(:refresh), 1000, true);

    reset();

    self._status.setCode(Status.INITIALIZED);
  }

  public function reset() as Void {
    _startTime = null;
    _elapsedTime = new Time.Duration(0);
  }

  private function convertTemperature(temperature as Float?) as Float? {
    if (temperature == null) {
      return null;
    }

    if (_systemUnits == System.UNIT_STATUTE) {
      return temperature * 1.8 + 32;
    }

    return temperature;
  }

  function refresh() as Void {
    if (isRunning()) {
      var now = new Time.Moment(Time.now().value());

      // NOTE: The _startTime cannot be null if the activity is already running
      _elapsedTime = now.subtract(_startTime) as Time.Duration;

      _heartRateData.addValue(Activity.getActivityInfo().currentHeartRate);

      var temperatureIterator = Toybox.SensorHistory.getTemperatureHistory({
        :period => _elapsedTime,
        :order => SensorHistory.ORDER_OLDEST_FIRST,
      });
      _temperatureData = new ToleranzData(temperatureIterator);

      if (_elapsedTime.value() % 60 == 0) {
        // Vibrate every minute
        if (Attention has :vibrate) {
          Attention.vibrate([
            // 100% strength, 500ms duration
            new Attention.VibeProfile(100, 500),
          ]);
        }
      }
    }

    WatchUi.requestUpdate();
  }

  public function destroy() as Void {
    _timer.stop();
  }

  public function start() as Void {
    if (!isRunning()) {
      reset();
      _startTime = new Time.Moment(Time.now().value());
      _status.setCode(Status.RUNNING);
    }
  }

  public function stop() as Void {
    if (isRunning()) {
      _status.setCode(Status.STOPPED);
    }
  }

  public function isRunning() as Boolean {
    return _status.getCode() == Status.RUNNING;
  }

  public function getStatus() as Status {
    return _status;
  }

  public function getElapsedTime() as Time.Duration {
    return _elapsedTime;
  }

  public function getCurrentHeartRate() as Number? {
    if (_heartRateData == null) {
      return null;
    }

    return _heartRateData.getLastValue();
  }

  public function getMinimumHeartRate() as Number? {
    if (_heartRateData == null) {
      return null;
    }

    return _heartRateData.getMinValue();
  }

  public function getMaximumHeartRate() as Number? {
    if (_heartRateData == null) {
      return null;
    }

    return _heartRateData.getMaxValue();
  }

  public function getCurrentTemperature() as Float? {
    if (_temperatureData == null) {
      return null;
    }

    return _temperatureData.getLastValue();
  }

  public function getMinimumTemperature() as Float? {
    if (_temperatureData == null) {
      return null;
    }

    return _temperatureData.getMinValue();
  }

  public function getMaximumTemperature() as Float? {
    if (_temperatureData == null) {
      return null;
    }

    return _temperatureData.getMaxValue();
  }

  public function getSelector() as Selector {
    return _selector;
  }

  public function getHeartRateData() as ToleranzData? {
    return _heartRateData;
  }

  public function getTemperatureData() as ToleranzData? {
    return _temperatureData;
  }
}
