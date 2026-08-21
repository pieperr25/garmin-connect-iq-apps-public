using Toybox.Math;
using Toybox.Test;

(:test)
function directHeadwindPointsUp(logger) {
    var relative = WindMath.relativeDegrees(0.0, 0.0);
    logger.debug("relative=" + relative);
    return relative == 0.0;
}

(:test)
function uTurnReversesHeadwindToTailwind(logger) {
    var relative = WindMath.relativeDegrees(0.0, Math.PI);
    logger.debug("relative=" + relative);
    return (relative > 179.9 && relative < 180.1);
}

(:test)
function windFromRightIsNinetyDegrees(logger) {
    var relative = WindMath.relativeDegrees(90.0, 0.0);
    logger.debug("relative=" + relative);
    return (relative > 89.9 && relative < 90.1);
}

(:test)
function riderTurnRotatesArrowEqually(logger) {
    var initial = WindMath.relativeDegrees(45.0, 0.0);
    var afterTurn = WindMath.relativeDegrees(45.0, Math.PI / 2.0);
    logger.debug("initial=" + initial + " after=" + afterTurn);
    return (initial > 44.9 && initial < 45.1 &&
            afterTurn > 314.9 && afterTurn < 315.1);
}

(:test)
function cardinalDirectionsWrap(logger) {
    return WindMath.cardinal(359.0).equals("N") &&
           WindMath.cardinal(45.0).equals("NE") &&
           WindMath.cardinal(270.0).equals("W");
}

(:test)
function fractionalAnglesWrapWithoutIntegerModulo(logger) {
    var positive = WindMath.normalizeDegrees(361.25);
    var negative = WindMath.normalizeDegrees(-0.75);
    var large = WindMath.normalizeDegrees(3600001.25);
    logger.debug("positive=" + positive + " negative=" + negative);
    return (positive > 1.24 && positive < 1.26 &&
            negative > 359.24 && negative < 359.26 &&
            large > 1.24 && large < 1.26);
}

(:test)
function validWeatherValuesAreAccepted(logger) {
    return WeatherData.isValid(12.5, 360.0, 20) &&
           WeatherData.isValid(0, 0.0, null);
}

(:test)
function malformedWeatherValuesAreRejected(logger) {
    return !WeatherData.isValid("12.5", 90.0, 20.0) &&
           !WeatherData.isValid(12.5, "90", 20.0) &&
           !WeatherData.isValid(-1.0, 90.0, 20.0) &&
           !WeatherData.isValid(12.5, 361.0, 20.0) &&
           !WeatherData.isValid(12.5, 90.0, "20");
}
