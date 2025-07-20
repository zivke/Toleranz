import Toybox.Graphics;
import Toybox.SensorHistory;
import Toybox.WatchUi;

class ToleranzView extends WatchUi.View {
  private var _state as ToleranzState;

  function initialize(state as ToleranzState) {
    self._state = state;

    View.initialize();
  }

  // Load your resources here
  function onLayout(dc as Dc) as Void {
    setLayout(Rez.Layouts.MainLayout(dc));
  }

  // Called when this View is brought to the foreground. Restore
  // the state of this View and prepare it to be shown. This includes
  // loading resources into memory.
  function onShow() as Void {}

  // Update the view
  function onUpdate(dc as Dc) as Void {
    drawStopwatch(dc);
    drawMainIcon(dc);
    drawCurrentTime(dc);
    drawTemperatureValues(dc);
    drawHeartRateValues(dc);
    drawChart(dc);

    // Call the parent onUpdate function to redraw the layout
    View.onUpdate(dc);
  }

  // Called when this View is removed from the screen. Save the
  // state of this View here. This includes freeing resources from
  // memory.
  function onHide() as Void {}

  private function drawCurrentTime(dc as Graphics.Dc) {
    var clockLabel = View.findDrawableById("clockValue") as Text?;
    if (clockLabel != null) {
      var currentTime = System.getClockTime();
      clockLabel.setText(
        currentTime.hour.format("%02d") + ":" + currentTime.min.format("%02d")
      );
    }
  }

  // Draw the temperature values
  private function drawTemperatureValues(dc as Graphics.Dc) {
    // Set the temperature label value
    var currentTemperature = _state.getCurrentTemperature();
    var currentTemperatureLabel =
      View.findDrawableById("currentTemperatureValue") as Text?;
    if (currentTemperatureLabel != null) {
      if (currentTemperature != null) {
        currentTemperatureLabel.setText(
          currentTemperature.format("%.1f") + "°"
        );
      } else {
        currentTemperatureLabel.setText("-");
      }
    }

    if (
      _state.isRunning() &&
      _state.getSelector().getType() == Selector.TEMPERATURE
    ) {
      // Set the minimum temperature label value
      var minimumTemperature = _state.getMinimumTemperature();
      var minimumTemperatureLabel =
        View.findDrawableById("minimumValue") as Text?;
      if (minimumTemperatureLabel != null) {
        if (minimumTemperature != null) {
          minimumTemperatureLabel.setText(
            minimumTemperature.format("%.1f") + "°"
          );
        } else {
          minimumTemperatureLabel.setText("-");
        }
      }

      // Set the maximum temperature label value
      var maximumTemperature = _state.getMaximumTemperature();
      var maximumTemperatureLabel =
        View.findDrawableById("maximumValue") as Text?;
      if (maximumTemperatureLabel != null) {
        if (maximumTemperature != null) {
          maximumTemperatureLabel.setText(
            maximumTemperature.format("%.1f") + "°"
          );
        } else {
          maximumTemperatureLabel.setText("-");
        }
      }
    }
  }

  private function drawHeartRateValues(dc as Graphics.Dc) {
    // Set the temperature label value
    var currentHeartRate = _state.getCurrentHeartRate();
    var currentHeartRateLabel =
      View.findDrawableById("currentHeartRateValue") as Text?;
    if (currentHeartRateLabel != null) {
      if (currentHeartRate != null) {
        currentHeartRateLabel.setText(currentHeartRate.format("%d"));
      } else {
        currentHeartRateLabel.setText("-");
      }
    }

    if (
      _state.isRunning() &&
      _state.getSelector().getType() == Selector.HEART_RATE
    ) {
      // Set the minimum and maximum heart rate label values
      var minimumHeartRate = _state.getMinimumHeartRate();
      var minTemperatureLabel = View.findDrawableById("minimumValue") as Text?;
      if (minTemperatureLabel != null) {
        if (minimumHeartRate != null) {
          minTemperatureLabel.setText(minimumHeartRate.format("%d"));
        } else {
          minTemperatureLabel.setText("-");
        }
      }

      var maximumHeartRate = _state.getMaximumHeartRate();
      var maxTemperatureLabel = View.findDrawableById("maximumValue") as Text?;
      if (maxTemperatureLabel != null) {
        if (maximumHeartRate != null) {
          maxTemperatureLabel.setText(maximumHeartRate.format("%d"));
        } else {
          maxTemperatureLabel.setText("-");
        }
      }
    }
  }

  private function drawMainIcon(dc as Graphics.Dc) {
    var heartSmallBlackIcon =
      View.findDrawableById("HeartSmallBlackIcon") as Bitmap?;
    if (heartSmallBlackIcon != null) {
      heartSmallBlackIcon.setVisible(
        _state.getSelector().getType() == Selector.HEART_RATE
      );
    }

    var thermometerSmallBlackIcon =
      View.findDrawableById("ThermometerSmallBlackIcon") as Bitmap?;
    if (thermometerSmallBlackIcon != null) {
      thermometerSmallBlackIcon.setVisible(
        _state.getSelector().getType() == Selector.TEMPERATURE
      );
    }
  }

  private function drawStopwatch(dc as Graphics.Dc) {
    // Set the stopwatch label value
    var stopwatchLabel = View.findDrawableById("stopwatchValue") as Text?;
    if (stopwatchLabel != null) {
      var currentElapsedSeconds = _state.getElapsedTime().value();
      var minutes = (currentElapsedSeconds / 60) % 60;
      var seconds = currentElapsedSeconds % 60;
      stopwatchLabel.setText(
        Lang.format("$1$:$2$", [minutes.format("%02d"), seconds.format("%02d")])
      );
    }
  }

  private function drawChart(dc as Graphics.Dc) {
    if (_state.isRunning()) {
      if (_state.getSelector().getType() == Selector.HEART_RATE) {
        // Set the chart minimum and maximum heart rate label values
        var minimumHeartRate = _state.getMinimumHeartRate();
        var minChartValueLabel =
          View.findDrawableById("minChartValue") as Text?;
        if (minChartValueLabel != null) {
          if (minimumHeartRate != null) {
            minChartValueLabel.setText(minimumHeartRate.format("%d"));
          } else {
            minChartValueLabel.setText("-");
          }
        }

        var maximumHeartRate = _state.getMaximumHeartRate();
        var maxChartValueLabel =
          View.findDrawableById("maxChartValue") as Text?;
        if (maxChartValueLabel != null) {
          if (maximumHeartRate != null) {
            maxChartValueLabel.setText(maximumHeartRate.format("%d"));
          } else {
            maxChartValueLabel.setText("-");
          }
        }

        var heartRateIterator = Toybox.SensorHistory.getHeartRateHistory({
          :period => _state.getElapsedTime(),
          :order => SensorHistory.ORDER_OLDEST_FIRST,
        });

        var heartRateChartDrawable =
          View.findDrawableById("Chart") as SensorHistoryChartDrawable?;
        if (heartRateChartDrawable != null) {
          heartRateChartDrawable.setSensorHistoryIterator(heartRateIterator);
        }
      }

      if (_state.getSelector().getType() == Selector.TEMPERATURE) {
        // Set the chart minimum and maximum temperature label values
        var minimumTemperature = _state.getMinimumTemperature();
        var minChartValueLabel =
          View.findDrawableById("minChartValue") as Text?;
        if (minChartValueLabel != null) {
          if (minimumTemperature != null) {
            minChartValueLabel.setText(
              Math.floor(minimumTemperature).format("%d")
            );
          } else {
            minChartValueLabel.setText("-");
          }
        }

        var maximumTemperature = _state.getMaximumTemperature();
        var maxChartValueLabel =
          View.findDrawableById("maxChartValue") as Text?;
        if (maxChartValueLabel != null) {
          if (maximumTemperature != null) {
            maxChartValueLabel.setText(
              Math.ceil(maximumTemperature).format("%d")
            );
          } else {
            maxChartValueLabel.setText("-");
          }
        }

        var temperatureIterator = Toybox.SensorHistory.getTemperatureHistory({
          :period => _state.getElapsedTime(),
          :order => SensorHistory.ORDER_OLDEST_FIRST,
        });

        var temperatureChartDrawable =
          View.findDrawableById("Chart") as SensorHistoryChartDrawable?;
        if (temperatureChartDrawable != null) {
          temperatureChartDrawable.setSensorHistoryIterator(
            temperatureIterator
          );
        }
      }
    }
  }
}
