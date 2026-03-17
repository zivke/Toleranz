import Toybox.Graphics;
import Toybox.Lang;
import Toybox.SensorHistory;
import Toybox.System;
import Toybox.Time;
import Toybox.WatchUi;

class ChartDrawable extends WatchUi.Drawable {
  private var _foregroundColor as Number;
  private var _backgroundColor as Number;

  private var _chartWidth as Number;
  private var _chartHeight as Number;
  private var _chartX as Number; // X position of the left-top corner of the chart
  private var _chartY as Number; // Y position of the left-top corner of the chart
  private var _chartMinimum as Number?;
  private var _chartMaximum as Number?;

  private var _data as ToleranzData?;

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

  function loadData(data as ToleranzData) {
    _data = data;

    var minValue = _data.getMinValue();
    var maxValue = _data.getMaxValue();

    if (minValue == null || maxValue == null) {
      // No valid data - skip drawing the chart
      _chartMinimum = null;
      _chartMaximum = null;
      _yScale = null;
    } else {
      // Adjust min and max to ensure a visible range
      _chartMinimum = Math.floor(minValue).toNumber() - 7;
      _chartMaximum = Math.ceil(maxValue).toNumber() + 7;

      _yScale = _chartHeight.toFloat() / (_chartMaximum - _chartMinimum);
    }
  }

  function draw(dc as Dc) {
    // Automatically determine the width of the drawable if non provided
    if (_chartWidth == 0) {
      if (System.getDeviceSettings().screenShape == System.SCREEN_SHAPE_ROUND) {
        // For round devices, use a smaller width to ensure the chart fits well within the screen
        _chartWidth = Math.floor(dc.getWidth() * 0.6).toNumber();
      } else {
        _chartWidth = Math.floor(dc.getWidth() * 0.7).toNumber();
      }
    }

    // Automatically determine the height of the drawable if non provided
    if (_chartHeight == 0) {
      _chartHeight = Math.floor(dc.getHeight() * 0.5).toNumber();
    }

    // Automatically determine the x location of the drawable if non provided
    if (_chartX == 0) {
      if (System.getDeviceSettings().screenShape == System.SCREEN_SHAPE_ROUND) {
        _chartX = Math.floor((dc.getWidth() - _chartWidth) / 2).toNumber();
      } else {
        _chartX = Math.floor(dc.getWidth() * 0.2).toNumber();
      }
    }

    // Automatically determine the y location of the drawable if non provided
    if (_chartY == 0) {
      _chartY = Math.floor(dc.getHeight() * 0.35).toNumber();
    }

    // Draw chart frame
    dc.setColor(_foregroundColor, _backgroundColor);
    dc.drawRectangle(_chartX, _chartY, _chartWidth, _chartHeight);

    if (
      _data == null ||
      _data.getDataSize() == 0 ||
      _chartMinimum == null ||
      _chartMaximum == null ||
      _yScale == null
    ) {
      // No valid data - skip drawing the chart
      return;
    }

    // Use to skip drawing some values if there are more values than
    // the chart width (e.g. 100 values for a 64px width chart)
    var multiplier =
      Math.floor(_data.getDataSize() / _chartWidth).toNumber() + 1;

    var chartBarWidth;
    if (_data.getDataSize() >= _chartWidth) {
      chartBarWidth = 1;
    } else {
      chartBarWidth = Math.floor(_chartWidth / _data.getDataSize()).toNumber();
    }

    // Move all chart bars to the right edge of the chart
    var xOffset =
      _chartWidth -
      chartBarWidth * Math.floor(_data.getDataSize() / multiplier).toNumber();

    // Draw chart bars
    for (var i = 0; i < _data.getDataSize(); i++) {
      if (multiplier != 1 && i % multiplier != 0) {
        continue; // Skip values based on the multiplier
      }

      var value = _data.getData()[i];
      if (value == null) {
        continue; // Skip null values
      }

      // Calculate the x position based on the index
      var x = _chartX + xOffset + (chartBarWidth * i) / multiplier;
      // Calculate the y position based on the value
      var y = Math.ceil(
        _chartY + _chartHeight - (value - _chartMinimum) * _yScale
      ).toNumber();

      // Draw the current chart bar
      dc.setColor(_foregroundColor, _backgroundColor);
      dc.fillRectangle(x, y, chartBarWidth, _chartHeight - (y - _chartY));

      // Draw the chart bar edge markers
      if (chartBarWidth > 1) {
        dc.setColor(_backgroundColor, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(
          x + chartBarWidth - 1,
          _chartY + _chartHeight,
          x + chartBarWidth - 1,
          _chartY + _chartHeight - 3
        );
      }
    }

    if (
      Math.round(_data.getMaxValue()).toNumber() !=
      Math.round(_data.getMinValue()).toNumber()
    ) {
      // Draw the min/max dotted lines
      var dottedLineY = Math.ceil(
        _chartY + _chartHeight - (_data.getMinValue() - _chartMinimum) * _yScale
      ).toNumber();
      drawHorizontalDottedLine(
        dc,
        _chartX,
        _chartX + _chartWidth,
        dottedLineY + 1,
        Graphics.COLOR_WHITE
      );

      dottedLineY = Math.ceil(
        _chartY + _chartHeight - (_data.getMaxValue() - _chartMinimum) * _yScale
      ).toNumber();
      drawHorizontalDottedLine(
        dc,
        _chartX,
        _chartX + _chartWidth,
        dottedLineY - 1,
        Graphics.COLOR_BLACK
      );

      // Draw the triangle
      var yMinTriangle = _chartY + _chartHeight - 7;
      drawMinTriangle(
        dc,
        Math.floor(
          _chartX +
            xOffset +
            chartBarWidth * (_data.getMinValueIndex() / multiplier + 0.5)
        ).toNumber(),
        yMinTriangle
      );

      // Draw the triangle
      var yMaxTriangle = _chartY + 6;
      drawMaxTriangle(
        dc,
        Math.floor(
          _chartX +
            xOffset +
            chartBarWidth * (_data.getMaxValueIndex() / multiplier + 0.5)
        ).toNumber(),
        yMaxTriangle
      );
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
