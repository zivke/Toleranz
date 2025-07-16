import Toybox.Graphics;
import Toybox.Lang;
import Toybox.SensorHistory;
import Toybox.System;
import Toybox.WatchUi;

class ChartDrawable extends WatchUi.Drawable {
  private var _sensorHistoryIterator as SensorHistoryIterator?;
  private var _foregroundColor as Number;
  private var _backgroundColor as Number;

  function setSensorHistoryIterator(
    sensorHistoryIterator as SensorHistoryIterator
  ) {
    self._sensorHistoryIterator = sensorHistoryIterator;
  }

  function initialize(params as Dictionary?) {
    Drawable.initialize(params);

    var foregroundColor = params.get(:color) as Number?;
    self._foregroundColor = foregroundColor
      ? foregroundColor
      : Graphics.COLOR_BLACK;

    var backgroundColor = params.get(:background) as Number?;
    self._backgroundColor = backgroundColor
      ? backgroundColor
      : Graphics.COLOR_WHITE;
  }

  function draw(dc as Dc) {
    var chartWidth = width as Number; // Chart width
    var chartHeight = height as Number; // Chart height
    var chartX = locX as Number; // X position of the chart
    var chartY = locY as Number; // Y position of the chart

    // Draw chart frame (FOR DEBUGGING PURPOSES)
    dc.drawRectangle(chartX, chartY, chartWidth, chartHeight);

    if (_sensorHistoryIterator == null) {
      // No sensor history iterator set, skip drawing the chart
      return;
    }

    var minValue = _sensorHistoryIterator.getMin();
    var maxValue = _sensorHistoryIterator.getMax();

    // If no valid data, skip drawing the chart
    if (minValue == null || maxValue == null) {
      // Missing data - skip drawing the chart
      return;
    }

    // Adjust min and max to ensure a visible range
    var chartMinimum = Math.floor(minValue).toNumber() - 5;
    var chartMaximum = Math.ceil(maxValue).toNumber() + 5;

    // Save the min and max triangle points
    var xMinTriangle = null;
    var xMaxTriangle = null;

    // Set colors
    dc.setColor(_foregroundColor, _backgroundColor);

    // Draw chart
    var yScale = chartHeight.toFloat() / (chartMaximum - chartMinimum);

    var sensorSample = _sensorHistoryIterator.next();
    var i = 0 as Number;
    while (sensorSample != null) {
      var value = sensorSample.data as Float?;
      if (value != null) {
        var x = chartX + chartWidth - 1 - i;
        var y = Math.ceil(
          chartY + chartHeight - 1 - (value - chartMinimum) * yScale
        );
        dc.drawLine(x, chartY + chartHeight - 1, x, y);

        // Save the min and max x positions
        if (value == minValue) {
          xMinTriangle = x;
        }

        if (value == maxValue) {
          xMaxTriangle = x;
        }
      }

      sensorSample = _sensorHistoryIterator.next();
      i++;
    }

    if (maxValue != minValue) {
      // Draw the min/max dotted lines
      var dottedLineY = Math.ceil(
        chartY + chartHeight - (minValue - chartMinimum) * yScale
      ).toNumber();
      drawHorizontalDottedLine(
        dc,
        chartX,
        chartX + chartWidth,
        dottedLineY + 1,
        Graphics.COLOR_WHITE
      );

      dottedLineY = Math.ceil(
        chartY + chartHeight - (maxValue - chartMinimum) * yScale
      ).toNumber();
      drawHorizontalDottedLine(
        dc,
        chartX,
        chartX + chartWidth,
        dottedLineY - 1,
        Graphics.COLOR_BLACK
      );

      // Draw the triangle if the minimum was found
      if (xMinTriangle != null) {
        var yMinTriangle = chartY + chartHeight - 7;
        drawMinTriangle(dc, xMinTriangle, yMinTriangle);
      }

      // Draw the triangle if the maximum was found
      if (xMaxTriangle != null) {
        var yMaxTriangle = chartY + 6;
        drawMaxTriangle(dc, xMaxTriangle, yMaxTriangle);
      }
    }

    // // Draw hour marks
    // dc.setColor(_backgroundColor, Graphics.COLOR_TRANSPARENT); // Inverted color
    // // 30 measurements per hour = one line every 30 values
    // for (var i = chartX + 30; i < chartX + chartWidth; i += 30) {
    //   dc.drawLine(i, chartY + chartHeight, i, chartY + chartHeight - 4);
    // }
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
