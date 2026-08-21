using Toybox.Lang;
using Toybox.Math;

module WindMath {
    const TWO_PI = Math.PI * 2.0;
    const RAD_TO_DEG = 180.0 / Math.PI;

    // Normalize degrees to [0, 360).
    function normalizeDegrees(degrees) {
        var normalized = degrees - (Math.floor(degrees / 360.0) * 360.0);
        return normalized;
    }

    // Returns where the wind comes from relative to the rider. Zero points up.
    function relativeDegrees(windFromDegrees, riderHeadingRadians) {
        var headingDegrees = riderHeadingRadians * RAD_TO_DEG;
        return normalizeDegrees(windFromDegrees - headingDegrees);
    }

    function cardinal(degrees) {
        var labels = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"];
        var index = ((normalizeDegrees(degrees) + 22.5) / 45.0).toNumber() % 8;
        return labels[index];
    }

    function relativeLabel(relativeDegreesValue) {
        var labels = [
            "HEADWIND",
            "HEAD / RIGHT",
            "RIGHT CROSS",
            "TAIL / RIGHT",
            "TAILWIND",
            "TAIL / LEFT",
            "LEFT CROSS",
            "HEAD / LEFT"
        ];
        var index = ((normalizeDegrees(relativeDegreesValue) + 22.5) / 45.0).toNumber() % 8;
        return labels[index];
    }

    function arrowColor(relativeDegreesValue) {
        var angle = normalizeDegrees(relativeDegreesValue);
        var distanceFromHeadwind = angle;
        if (distanceFromHeadwind > 180.0) {
            distanceFromHeadwind = 360.0 - distanceFromHeadwind;
        }

        if (distanceFromHeadwind <= 60.0) {
            return 0xFF3333;
        }
        if (distanceFromHeadwind >= 120.0) {
            return 0x33CC66;
        }
        return 0xFFAA00;
    }

    function minValue(left, right) {
        return (left < right) ? left : right;
    }

    function maxValue(left, right) {
        return (left > right) ? left : right;
    }
}

module WeatherData {
    const MAX_WIND_MPH = 500.0;

    function isNumeric(value) {
        return value instanceof Lang.Number ||
               value instanceof Lang.Float ||
               value instanceof Lang.Long ||
               value instanceof Lang.Double;
    }

    // Keep untrusted API values out of rendering and angle calculations.
    function isValid(speed, direction, gust) {
        if (!isNumeric(speed) || speed < 0.0 || speed > MAX_WIND_MPH) {
            return false;
        }
        if (!isNumeric(direction) || direction < 0.0 || direction > 360.0) {
            return false;
        }
        if (gust != null &&
            (!isNumeric(gust) || gust < 0.0 || gust > MAX_WIND_MPH)) {
            return false;
        }
        return true;
    }
}

// Circular exponential smoothing avoids the 359-to-0 degree discontinuity.
class HeadingSmoother {
    const ALPHA = 0.40;

    var _x = null;
    var _y = null;

    function add(radians) {
        var newX = Math.cos(radians);
        var newY = Math.sin(radians);

        if (_x == null || _y == null) {
            _x = newX;
            _y = newY;
        } else {
            _x = (ALPHA * newX) + ((1.0 - ALPHA) * _x);
            _y = (ALPHA * newY) + ((1.0 - ALPHA) * _y);
        }

        var smoothed = Math.atan2(_y, _x);
        if (smoothed < 0.0) {
            smoothed += WindMath.TWO_PI;
        }
        return smoothed;
    }
}
