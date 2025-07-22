import Toybox.Lang;
import Toybox.SensorHistory;
import Toybox.Time;

class ToleranzData {
  private var _data as Lang.Array<Number or Float or Null> = [];

  private var _minValue as Float or Number or Null;
  private var _minValueIndex as Number?;
  private var _maxValue as Float or Number or Null;
  private var _maxValueIndex as Number?;

  function initialize(sensorHistoryIterator as SensorHistoryIterator?) {
    if (sensorHistoryIterator != null) {
      // Prepare data
      var sensorSample = sensorHistoryIterator.next();
      var i = 0 as Number;
      while (sensorSample != null) {
        var value = sensorSample.data;
        _data.add(value);

        if (value != null) {
          // Save the min and max indices
          if (_minValue == null || value < _minValue) {
            _minValue = value;
            _minValueIndex = i;
          }

          if (_maxValue == null || value > _maxValue) {
            _maxValue = value;
            _maxValueIndex = i;
          }
        }

        sensorSample = sensorHistoryIterator.next();
        i++;
      }
    }
  }

  public function getData() as Lang.Array<Number or Float or Null> {
    return _data;
  }

  public function getDataSize() as Number {
    return _data.size();
  }

  public function getMinValue() as Float or Number or Null {
    return _minValue;
  }

  public function getMinValueIndex() as Number? {
    return _minValueIndex;
  }

  public function getMaxValue() as Float or Number or Null {
    return _maxValue;
  }

  public function getMaxValueIndex() as Number? {
    return _maxValueIndex;
  }

  public function getLastValue() as Number or Float or Null {
    if (_data.size() > 0) {
      return _data[_data.size() - 1];
    }
    return null;
  }

  public function addValue(value as Number or Float or Null) as Void {
    _data.add(value);

    if (value != null) {
      // Update min and max values
      if (_minValue == null || value < _minValue) {
        _minValue = value;
        _minValueIndex = _data.size() - 1;
      }

      if (_maxValue == null || value > _maxValue) {
        _maxValue = value;
        _maxValueIndex = _data.size() - 1;
      }
    }
  }
}
