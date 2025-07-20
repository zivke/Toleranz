import Toybox.Graphics;
import Toybox.Lang;
import Toybox.SensorHistory;
import Toybox.System;
import Toybox.Time;
import Toybox.WatchUi;

class SensorHistoryChartDrawable extends WatchUi.Drawable {
  private var _foregroundColor as Number;
  private var _backgroundColor as Number;

  private var _chartWidth as Number;
  private var _chartHeight as Number;
  private var _chartX as Number; // X position of the left-top corner of the chart
  private var _chartY as Number; // Y position of the left-top corner of the chart
  private var _chartMinimum as Number?;
  private var _chartMaximum as Number?;

  private var _data as Lang.Array<Number or Float or Null> = [];

  private var _minValue as Float or Number or Null;
  private var _minValueIndex as Number?;
  private var _maxValue as Float or Number or Null;
  private var _maxValueIndex as Number?;

  private var _yScale as Float?;

  function initialize(params as Dictionary) {
    Drawable.initialize(params);

    var foregroundColor = params.get(:color) as Number?;
    self._foregroundColor = foregroundColor
      ? foregroundColor
      : Graphics.COLOR_BLACK;

    var backgroundColor = params.get(:background) as Number?;
    self._backgroundColor = backgroundColor
      ? backgroundColor
      : Graphics.COLOR_WHITE;

    self._chartWidth = width as Number;
    self._chartHeight = height as Number;
    self._chartX = locX as Number;
    self._chartY = locY as Number;
  }

  function loadData(sensorHistoryIterator as SensorHistoryIterator) as Boolean {
    _data = [];

    // If no valid data, skip drawing the chart
    _minValue = sensorHistoryIterator.getMin();
    _maxValue = sensorHistoryIterator.getMax();

    var newestSampleTime = sensorHistoryIterator.getNewestSampleTime();
    var oldestSampleTime = sensorHistoryIterator.getOldestSampleTime();

    if (
      _minValue == null ||
      _maxValue == null ||
      newestSampleTime == null ||
      oldestSampleTime == null
    ) {
      // Missing data - skip drawing the chart
      return false;
    }

    var elapsedTime =
      newestSampleTime.subtract(oldestSampleTime) as Time.Duration;
    if (elapsedTime.value() <= 0) {
      // Data not valid
      return false;
    }

    var maxHistorySize = elapsedTime.value(); // Maximum history size in seconds
    _data = new Lang.Array<Number or Float or Null>[maxHistorySize];

    // Adjust min and max to ensure a visible range
    _chartMinimum = Math.floor(_minValue).toNumber() - 5;
    _chartMaximum = Math.ceil(_maxValue).toNumber() + 5;

    _yScale = _chartHeight.toFloat() / (_chartMaximum - _chartMinimum);

    // Prepare data
    var sensorSample = sensorHistoryIterator.next();
    var i = 0 as Number;
    while (sensorSample != null) {
      var value = sensorSample.data as Float?;
      _data[i] = value;

      if (value != null) {
        // Save the min and max indices
        if (value == _minValue) {
          _minValueIndex = i;
        }

        if (value == _maxValue) {
          _maxValueIndex = i;
        }
      }

      sensorSample = sensorHistoryIterator.next();
      i++;
    }

    if (i > 0) {
      _data = _data.slice(0, i); // Remove unused elements
    }

    return true;
  }

  function draw(dc as Dc) {
    // Draw chart frame
    dc.setColor(_foregroundColor, _backgroundColor);
    dc.drawRectangle(_chartX, _chartY, _chartWidth, _chartHeight);

    if (
      _data.size() == 0 ||
      _minValue == null ||
      _maxValue == null ||
      _chartMinimum == null ||
      _chartMaximum == null ||
      _yScale == null
    ) {
      // No valid data - skip drawing the chart
      return;
    }

    var rectangleWidth = Math.floor(_chartWidth / _data.size()).toNumber();

    // Move all rectangles to the right edge of the chart
    var xOffset = _chartWidth - rectangleWidth * _data.size();

    // Draw chart
    for (var i = 0; i < _data.size(); i++) {
      var value = _data[i];
      if (value == null) {
        continue; // Skip null values
      }

      // Calculate the x position based on the index
      var x = _chartX + xOffset + rectangleWidth * i;
      // Calculate the y position based on the value
      var y = Math.ceil(
        _chartY + _chartHeight - (value - _chartMinimum) * _yScale
      ).toNumber();

      // Draw the rectangle
      dc.setColor(_foregroundColor, _backgroundColor);
      dc.fillRectangle(x, y, rectangleWidth, _chartHeight - (y - _chartY));
    }

    if (_maxValue != _minValue) {
      // Draw the min/max dotted lines
      var dottedLineY = Math.ceil(
        _chartY + _chartHeight - (_minValue - _chartMinimum) * _yScale
      ).toNumber();
      drawHorizontalDottedLine(
        dc,
        _chartX,
        _chartX + _chartWidth,
        dottedLineY + 1,
        Graphics.COLOR_WHITE
      );

      dottedLineY = Math.ceil(
        _chartY + _chartHeight - (_maxValue - _chartMinimum) * _yScale
      ).toNumber();
      drawHorizontalDottedLine(
        dc,
        _chartX,
        _chartX + _chartWidth,
        dottedLineY - 1,
        Graphics.COLOR_BLACK
      );

      // Draw the triangle if the minimum was found
      if (_minValueIndex != null) {
        var yMinTriangle = _chartY + _chartHeight - 7;
        drawMinTriangle(
          dc,
          Math.floor(
            _chartX + xOffset + rectangleWidth * (_minValueIndex + 0.5)
          ).toNumber(),
          yMinTriangle
        );
      }

      // Draw the triangle if the maximum was found
      if (_maxValueIndex != null) {
        var yMaxTriangle = _chartY + 6;
        drawMaxTriangle(
          dc,
          Math.floor(
            _chartX + xOffset + rectangleWidth * (_maxValueIndex + 0.5)
          ).toNumber(),
          yMaxTriangle
        );
      }
    }
  }

  // Draw the triangle to indicate the minimum temperature value
  private function drawMinTriangle(
    dc as Graphics.Dc,
    pointX as Number,
    pointY as Number
  ) {
    // Create the polygon points array
    var points = [
      [pointX, pointY],
      [pointX + 4, pointY + 4],
      [pointX - 4, pointY + 4],
    ];

    // Draw the triangle
    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
    dc.fillPolygon(points);

    // Draw the triangle outline (so it is visible if it goes outside of the chart)
    dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
    dc.drawLine(pointX, pointY - 1, pointX + 5, pointY + 4);
    dc.drawLine(pointX, pointY - 1, pointX - 5, pointY + 4);
    dc.drawLine(pointX + 5, pointY + 4, pointX - 5, pointY + 4);
  }

  // Draw the triangle to indicate the minimum temperature value
  private function drawMaxTriangle(
    dc as Graphics.Dc,
    pointX as Number,
    pointY as Number
  ) {
    // Create the polygon points array
    var points = [
      [pointX, pointY],
      [pointX + 4, pointY - 4],
      [pointX - 4, pointY - 4],
    ];

    // Draw the triangle
    dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
    dc.fillPolygon(points);
  }

  private function drawHorizontalDottedLine(
    dc as Dc,
    startX as Number,
    endX as Number,
    y as Number,
    color as Number
  ) {
    dc.setColor(color, Graphics.COLOR_TRANSPARENT);
    for (var i = startX; i < endX; i += 2) {
      dc.drawPoint(i, y);
    }
  }
}
