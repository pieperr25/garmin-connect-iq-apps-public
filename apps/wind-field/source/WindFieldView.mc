using Toybox.Activity;
using Toybox.Communications;
using Toybox.Graphics;
using Toybox.Lang;
using Toybox.Math;
using Toybox.PersistedContent;
using Toybox.Position;
using Toybox.Time;
using Toybox.WatchUi;

class WindFieldView extends WatchUi.DataField {
    const WEATHER_URL = "https://api.open-meteo.com/v1/forecast";
    const REFRESH_SECONDS = 15 * 60;
    const RETRY_SECONDS = 60;

    var _headingSmoother;
    var _headingRadians = null;
    var _location as Position.Location? = null;

    var _windSpeedMph = null;
    var _windGustMph = null;
    var _windFromDegrees = null;

    var _lastAttemptAt = 0;
    var _lastSuccessAt = 0;
    var _requestInFlight = false;
    var _lastRequestFailed = false;
    var _status = "WAITING FOR GPS";

    function initialize() {
        DataField.initialize();
        _headingSmoother = new HeadingSmoother();
    }

    // Garmin supplies Activity.Info here once per second.
    function compute(info as Activity.Info) as Void {
        var heading = null;
        if (info has :track && info.track != null) {
            heading = info.track;
        } else if (info has :currentHeading && info.currentHeading != null) {
            heading = info.currentHeading;
        }

        if (heading != null) {
            _headingRadians = _headingSmoother.add(heading);
        }

        if (info has :currentLocation && info.currentLocation != null) {
            _location = info.currentLocation;
            maybeRefreshWeather();
        }
    }

    function maybeRefreshWeather() {
        if (_location == null || _requestInFlight) {
            return;
        }

        var now = Time.now().value();
        var interval = _lastRequestFailed ? RETRY_SECONDS : REFRESH_SECONDS;
        if (_lastAttemptAt != 0 && (now - _lastAttemptAt) < interval) {
            return;
        }

        var coordinates = _location.toDegrees();
        var parameters = {
            "latitude" => coordinates[0],
            "longitude" => coordinates[1],
            "current" => "wind_speed_10m,wind_direction_10m,wind_gusts_10m",
            "wind_speed_unit" => "mph",
            "timezone" => "auto",
            "forecast_days" => 1
        };
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :headers => {"Accept" => "application/json"},
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };

        _lastAttemptAt = now;
        _requestInFlight = true;
        _status = "FETCHING WIND";
        try {
            Communications.makeWebRequest(
                WEATHER_URL,
                parameters,
                options,
                method(:onWeatherResponse)
            );
        } catch (error) {
            markWeatherFailure();
        }
    }

    function onWeatherResponse(
        responseCode as Lang.Number,
        data as Lang.Dictionary or Lang.String or PersistedContent.Iterator or Null
    ) as Void {
        _requestInFlight = false;

        if (responseCode == 200 && data instanceof Lang.Dictionary) {
            try {
                var current = data["current"];
                if (current instanceof Lang.Dictionary) {
                    var speed = current["wind_speed_10m"];
                    var direction = current["wind_direction_10m"];
                    var gust = current["wind_gusts_10m"];

                    if (WeatherData.isValid(speed, direction, gust)) {
                        _windSpeedMph = speed;
                        _windFromDegrees = WindMath.normalizeDegrees(direction);
                        _windGustMph = gust;
                        _lastSuccessAt = Time.now().value();
                        _lastRequestFailed = false;
                        _status = "LIVE";
                        return;
                    }
                }
            } catch (error) {
                // Treat malformed or incomplete data like any other request error.
            }
        }

        markWeatherFailure();
    }

    function markWeatherFailure() {
        _requestInFlight = false;
        _lastRequestFailed = true;
        _status = (_windSpeedMph == null) ? "WEATHER UNAVAILABLE" : "CACHED";
    }

    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        var width = dc.getWidth();
        var height = dc.getHeight();

        if (_windSpeedMph == null || _windFromDegrees == null) {
            drawWaiting(dc, width, height);
            return;
        }

        if (_headingRadians == null) {
            drawNoHeading(dc, width, height);
            return;
        }

        var relative = WindMath.relativeDegrees(_windFromDegrees, _headingRadians);
        if (height >= 150) {
            drawFull(dc, width, height, relative);
        } else {
            drawCompact(dc, width, height, relative);
        }
    }

    function drawWaiting(dc, width, height) {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            width / 2,
            (height / 2) - 12,
            Graphics.FONT_SMALL,
            _status,
            Graphics.TEXT_JUSTIFY_CENTER
        );
    }

    function drawNoHeading(dc, width, height) {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width / 2, height * 0.25, Graphics.FONT_SMALL,
            formatSpeed(), Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(width / 2, height * 0.55, Graphics.FONT_XTINY,
            "RIDE TO SET DIRECTION", Graphics.TEXT_JUSTIFY_CENTER);
    }

    function drawFull(dc, width, height, relative) {
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width / 2, 4, Graphics.FONT_XTINY,
            "WIND FROM " + WindMath.cardinal(_windFromDegrees),
            Graphics.TEXT_JUSTIFY_CENTER);

        var arrowLength = WindMath.minValue(width * 0.48, height * 0.36);
        drawArrow(dc, width / 2, height * 0.35, arrowLength, relative);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width / 2, height * 0.60, Graphics.FONT_LARGE,
            formatSpeed(), Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(WindMath.arrowColor(relative), Graphics.COLOR_TRANSPARENT);
        dc.drawText(width / 2, height * 0.76, Graphics.FONT_SMALL,
            WindMath.relativeLabel(relative), Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width / 2, height - 24, Graphics.FONT_XTINY,
            formatFooter(), Graphics.TEXT_JUSTIFY_CENTER);
    }

    function drawCompact(dc, width, height, relative) {
        var arrowLength = WindMath.minValue(width * 0.28, height * 0.58);
        drawArrow(dc, width * 0.22, height / 2, arrowLength, relative);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width * 0.58, height * 0.17, Graphics.FONT_MEDIUM,
            formatSpeed(), Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(WindMath.arrowColor(relative), Graphics.COLOR_TRANSPARENT);
        dc.drawText(width * 0.58, height * 0.58, Graphics.FONT_XTINY,
            WindMath.relativeLabel(relative), Graphics.TEXT_JUSTIFY_CENTER);
    }

    function drawArrow(dc, centerX, centerY, length, relativeDegreesValue) {
        var radians = relativeDegreesValue * Math.PI / 180.0;
        var directionX = Math.sin(radians);
        var directionY = -Math.cos(radians);
        var perpendicularX = Math.cos(radians);
        var perpendicularY = Math.sin(radians);

        var halfLength = length / 2.0;
        var headLength = WindMath.maxValue(12.0, length * 0.30);
        var shaftHalfWidth = WindMath.maxValue(3.0, length * 0.055);
        var headHalfWidth = WindMath.maxValue(8.0, length * 0.16);

        var tipX = centerX + (directionX * halfLength);
        var tipY = centerY + (directionY * halfLength);
        var tailX = centerX - (directionX * halfLength);
        var tailY = centerY - (directionY * halfLength);
        var headBaseX = tipX - (directionX * headLength);
        var headBaseY = tipY - (directionY * headLength);

        var points = [
            point(tailX + perpendicularX * shaftHalfWidth,
                  tailY + perpendicularY * shaftHalfWidth),
            point(headBaseX + perpendicularX * shaftHalfWidth,
                  headBaseY + perpendicularY * shaftHalfWidth),
            point(headBaseX + perpendicularX * headHalfWidth,
                  headBaseY + perpendicularY * headHalfWidth),
            point(tipX, tipY),
            point(headBaseX - perpendicularX * headHalfWidth,
                  headBaseY - perpendicularY * headHalfWidth),
            point(headBaseX - perpendicularX * shaftHalfWidth,
                  headBaseY - perpendicularY * shaftHalfWidth),
            point(tailX - perpendicularX * shaftHalfWidth,
                  tailY - perpendicularY * shaftHalfWidth)
        ];

        dc.setColor(WindMath.arrowColor(relativeDegreesValue), Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon(points);
    }

    function point(x, y) {
        return [x.toNumber(), y.toNumber()];
    }

    function formatSpeed() {
        return _windSpeedMph.format("%.0f") + " mph";
    }

    function formatFooter() {
        var gust = "";
        if (_windGustMph != null) {
            gust = "G " + _windGustMph.format("%.0f") + "  ";
        }

        if (_lastSuccessAt == 0) {
            return gust + _status;
        }

        var ageSeconds = Time.now().value() - _lastSuccessAt;
        var ageMinutes = (ageSeconds / 60).toNumber();
        if (ageMinutes < 1) {
            return gust + "UPDATED NOW";
        }
        return gust + "UPDATED " + ageMinutes.format("%d") + "m";
    }
}
