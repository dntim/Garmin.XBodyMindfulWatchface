import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.SensorHistory;
using Toybox.Time.Gregorian as Calendar;


class XBodyMindfulWatchfaceView extends WatchUi.WatchFace {

    // Variables
    var isActive = true;
    private var _middleDrawAreaY1 as Number;
    private var _middleDrawAreaY2 as Number;

    function initialize() {
        WatchFace.initialize();

        var settings = System.getDeviceSettings();
        var hotNumberFontHeight = Graphics.getFontHeight(Graphics.FONT_NUMBER_HOT);
        // var hotNumberFontWidth = hotNumberFontHeight * 2 / 3;
        _middleDrawAreaY1 = (settings.screenHeight - hotNumberFontHeight) / 2;
        _middleDrawAreaY2 = _middleDrawAreaY1 + hotNumberFontHeight;
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.WatchFace(dc));
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
        isActive = true;
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        // Get the current time and format it correctly
        var timeFormat = "$1$:$2$";
        // if (isActive) {
        //     timeFormat = "$1$:$2$:$3$";
        // }
        var clockTime = System.getClockTime();
        var hours = clockTime.hour;
        // if (!System.getDeviceSettings().is24Hour) {
        //     if (hours > 12) {
        //         hours = hours - 12;
        //     }
        // } else {
            if (getApp().getProperty("UseMilitaryFormat")) {
                timeFormat = "$1$$2$";
                // if (isActive) {
                //     timeFormat = "$1$$2$$3$";
                // }
                hours = hours.format("%02d");
            }
        // }
        var timeString = Lang.format(timeFormat, [hours, clockTime.min.format("%02d")]);
        // var timeString = isActive ? Lang.format(timeFormat, [hours, clockTime.min.format("%02d"), clockTime.sec.format("%02d")]) : Lang.format(timeFormat, [hours, clockTime.min.format("%02d")]);

        // Update the time label
        var view = View.findDrawableById("TimeLabel") as Text;
        // view.setFont(Graphics.);
        view.setText(timeString);

        // Update the date labels
        var now = Time.now();
        var info = Calendar.info(now, Time.FORMAT_LONG);
        // view = View.findDrawableById("DateLabel") as Text;
        // view.setText(Lang.format("$1$ $2$ $3$", [info.day_of_week, info.month, info.day]));
        view = View.findDrawableById("DateLabel1") as Text;
        view.setText(info.day_of_week);
        view = View.findDrawableById("DateLabel2") as Text;
        view.setText(info.day.toString());
        view = View.findDrawableById("DateLabel3") as Text;
        view.setText(info.month);

        // Update the dntim label
        view = View.findDrawableById("AuthorLabel") as Text;
        view.setText("@dntim");

        // Update body battery
        var bbValue = "N/A";
        var bodyBatteryIterator = getBodyBatteryIterator(1, false);
        if (bodyBatteryIterator != null) {
            var bodyBattery = bodyBatteryIterator.next();
            if (bodyBattery != null) {
                if (bodyBattery.data != null) {
                    bbValue = bodyBattery.data.format("%d") + "%";
                }
                else {
                    bbValue = "-";
                }
            }
            else {
                bbValue = "N/A (s)";
            }
        }
        else {
            bbValue = "N/A (i)";
        }
        view = View.findDrawableById("BodyBatteryLabel") as Text;
        view.setColor(Graphics.COLOR_LT_GRAY as Number);
        view.setText(bbValue);

        // Get last body battery charged values
        var bbLastChargedValue = "Best at ? % x h. ago";
        bodyBatteryIterator = getBodyBatteryIterator(1, true);
        var bbHighestValue = 0;
        var bbLastCharged = now.subtract(new Time.Duration(3600*24*365));
        if (bodyBatteryIterator != null) {
            var sample = bodyBatteryIterator.next();
            while (sample != null) {
                if (bbLastCharged == null) {
                    bbLastCharged = sample.when;
                }
                if (sample.data != null && sample.data > bbHighestValue) {
                    bbHighestValue = sample.data;
                    bbLastCharged = sample.when;
                }
                sample = bodyBatteryIterator.next();
            }
        }
        if (bbHighestValue > 0) {
            var hoursDiff = Math.round(now.subtract(bbLastCharged).value() / 3600);
            bbLastChargedValue = Lang.format("Best at $1$% $2$ h. ago", [bbHighestValue.format("%d"), hoursDiff.format("%d")]);
        }
        view = View.findDrawableById("LastBobyChargedLabel") as Text;
        // view.setColor(Graphics.COLOR_LT_GRAY as Number);
        view.setText(bbLastChargedValue);

        // Call the parent onUpdate function to redraw the layout
        View.onUpdate(dc);
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
        isActive = false;
    }

    // The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() as Void {
        isActive = true;
    }

    // Terminate any active timers and prepare for slow updates.
    function onEnterSleep() as Void {
        isActive = false;
    }

    function getBodyBatteryIterator(numberOfSamples as Number, getStats as Boolean) {
        // Check device for SensorHistory compatibility
        if ((Toybox has :SensorHistory) && (Toybox.SensorHistory has :getBodyBatteryHistory)) {
            // Set up the method with parameters
            if (getStats) {
                var statPeriod = new Time.Duration(3600*18);
                return Toybox.SensorHistory.getBodyBatteryHistory({:period=>statPeriod});
            }
            else {
                return Toybox.SensorHistory.getBodyBatteryHistory({:period=>numberOfSamples});
            }
        }
        return null;
    }
}
