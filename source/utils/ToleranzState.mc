import Toybox.Activity;
import Toybox.ActivityMonitor;
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

  private var _currentHeartRate as Number?;
  private var _maximumHeartRate as Number?;
  private var _minimumHeartRate as Number?;

  private var _currentTemperature as Float?;
  private var _maximumTemperature as Float?;
  private var _minimumTemperature as Float?;

  function initialize() {
    self._systemUnits = System.getDeviceSettings().temperatureUnits;
    self._status = new Status();
    self._selector = new Selector();
    self._timer = new Timer.Timer();
    self._elapsedTime = new Time.Duration(0);

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

    _currentHeartRate = Activity.getActivityInfo().currentHeartRate;

    processTemperature(1);
  }

  private function processTemperature(period as Number or Time.Duration) {
    var temperatureIterator = Toybox.SensorHistory.getTemperatureHistory({
      :period => period,
      :order => SensorHistory.ORDER_NEWEST_FIRST,
    });
    var temperatureSensorSample = temperatureIterator.next();
    if (temperatureSensorSample != null) {
      _currentTemperature = convertTemperature(
        temperatureSensorSample.data as Float?
      );
    }

    if (isRunning()) {
      _maximumTemperature = convertTemperature(
        temperatureIterator.getMax() as Float?
      );
      _minimumTemperature = convertTemperature(
        temperatureIterator.getMin() as Float?
      );
    }
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
    _currentHeartRate = Activity.getActivityInfo().currentHeartRate;

    if (isRunning()) {
      var now = new Time.Moment(Time.now().value());
      _elapsedTime = now.subtract(_startTime) as Time.Duration;

      if (_currentHeartRate != null) {
        if (
          _minimumHeartRate == null ||
          _currentHeartRate < _minimumHeartRate
        ) {
          _minimumHeartRate = _currentHeartRate;
        }

        if (
          _maximumHeartRate == null ||
          _currentHeartRate > _maximumHeartRate
        ) {
          _maximumHeartRate = _currentHeartRate;
        }
      }

      if (_elapsedTime.value() % 60 == 0) {
        processTemperature(_elapsedTime);
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
    return !_status.hasError() && _status.getCode() == Status.RUNNING;
  }

  public function getStatus() as Status {
    return _status;
  }

  public function getElapsedTime() as Time.Duration {
    return _elapsedTime;
  }

  public function getCurrentHeartRate() as Number? {
    return _currentHeartRate;
  }

  public function getMinimumHeartRate() as Number? {
    return _minimumHeartRate;
  }

  public function getMaximumHeartRate() as Number? {
    return _maximumHeartRate;
  }

  public function getCurrentTemperature() as Float? {
    return _currentTemperature;
  }

  public function getMinimumTemperature() as Float? {
    return _minimumTemperature;
  }

  public function getMaximumTemperature() as Float? {
    return _maximumTemperature;
  }

  public function getSelector() as Selector {
    return _selector;
  }
}
