import Toybox.Graphics;
import Toybox.Lang;
import Toybox.SensorHistory;
import Toybox.System;
import Toybox.Time;
import Toybox.WatchUi;

class ChartDrawable extends WatchUi.Drawable {
  private var _sensorHistoryIterator as SensorHistoryIterator?;

  private var _foregroundColor as Number;
  private var _backgroundColor as Number;

  private var _chartWidth as Number;
  private var _chartHeight as Number;
  private var _chartX as Number; // X position of the left-top corner of the chart
  private var _chartY as Number; // Y position of the left-top corner of the chart

  function setSensorHistoryIterator(
    sensorHistoryIterator as SensorHistoryIterator
  ) {
    self._sensorHistoryIterator = sensorHistoryIterator;
  }

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

  function draw(dc as Dc) {
    // Draw chart frame
    dc.drawRectangle(_chartX, _chartY, _chartWidth, _chartHeight);

    // If no valid data, skip drawing the chart
    if (_sensorHistoryIterator == null) {
      return;
    }

    var minValue = _sensorHistoryIterator.getMin();
    var maxValue = _sensorHistoryIterator.getMax();
    var newestSampleTime = _sensorHistoryIterator.getNewestSampleTime();
    var oldestSampleTime = _sensorHistoryIterator.getOldestSampleTime();

    if (
      minValue == null ||
      maxValue == null ||
      newestSampleTime == null ||
      oldestSampleTime == null
    ) {
      // Missing data - skip drawing the chart
      return;
    }

    var elapsedTime =
      newestSampleTime.subtract(oldestSampleTime) as Time.Duration;
    if (elapsedTime.value() <= 0) {
      // No valid data - skip drawing the chart
      return;
    }

    var maxHistorySize = elapsedTime.value(); // Maximum history size in seconds
    var valueHistory = new Lang.Array<Number or Float or Null>[maxHistorySize];

    // Adjust min and max to ensure a visible range
    var chartMinimum = Math.floor(minValue).toNumber() - 5;
    var chartMaximum = Math.ceil(maxValue).toNumber() + 5;

    // Save the min and max indices
    var minValueIndex = null;
    var maxValueIndex = null;

    // Set colors
    dc.setColor(_foregroundColor, _backgroundColor);

    // Draw chart
    var yScale = _chartHeight.toFloat() / (chartMaximum - chartMinimum);

    var sensorSample = _sensorHistoryIterator.next();
    var i = 0 as Number;
    while (sensorSample != null) {
      var value = sensorSample.data as Float?;
      valueHistory[i] = value;

      if (value != null) {
        // Save the min and max indices
        if (value == minValue) {
          minValueIndex = i;
        }

        if (value == maxValue) {
          maxValueIndex = i;
        }
      }

      sensorSample = _sensorHistoryIterator.next();
      i++;
    }

    valueHistory = valueHistory.slice(0, i); // Remove unused elements

    var rectangleWidth = Math.ceil(
      _chartWidth / valueHistory.size()
    ).toNumber();
    for (i = 0; i < valueHistory.size(); i++) {
      var value = valueHistory[i];
      if (value == null) {
        continue; // Skip null values
      }

      // Calculate the x position based on the index
      var x = _chartX + rectangleWidth * i;
      // Calculate the y position based on the value
      var y = Math.ceil(
        _chartY + _chartHeight - (value - chartMinimum) * yScale
      ).toNumber();

      // Draw the rectangle
      dc.fillRectangle(x, y, rectangleWidth, _chartHeight - (y - _chartY));
    }

    if (maxValue != minValue) {
      // Draw the min/max dotted lines
      var dottedLineY = Math.ceil(
        _chartY + _chartHeight - (minValue - chartMinimum) * yScale
      ).toNumber();
      drawHorizontalDottedLine(
        dc,
        _chartX,
        _chartX + _chartWidth,
        dottedLineY + 1,
        Graphics.COLOR_WHITE
      );

      dottedLineY = Math.ceil(
        _chartY + _chartHeight - (maxValue - chartMinimum) * yScale
      ).toNumber();
      drawHorizontalDottedLine(
        dc,
        _chartX,
        _chartX + _chartWidth,
        dottedLineY - 1,
        Graphics.COLOR_BLACK
      );

      // Draw the triangle if the minimum was found
      if (minValueIndex != null) {
        var yMinTriangle = _chartY + _chartHeight - 7;
        drawMinTriangle(
          dc,
          Math.round(_chartX + rectangleWidth * (minValueIndex + 0.5)).toNumber(),
          yMinTriangle
        );
      }

      // Draw the triangle if the maximum was found
      if (maxValueIndex != null) {
        var yMaxTriangle = _chartY + 6;
        drawMaxTriangle(
          dc,
          Math.round(_chartX + rectangleWidth * (maxValueIndex + 0.5)).toNumber(),
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
