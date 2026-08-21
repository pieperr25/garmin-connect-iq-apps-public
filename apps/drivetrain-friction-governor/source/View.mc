import Toybox.Activity;
import Toybox.Attention;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class DrivetrainFrictionGovernorView extends WatchUi.DataField {
    private var currentState as Number;
    private var lastState as Number;
    private var _lastRearIndex as Number;
    private var _hasPreviousGearData as Boolean;
    private var _rearGearText as String;
    private var _gearText as Array<String>;
    private var _doubleBeepOptions as {
        :toneProfile as Array<Attention.ToneProfile>
    };

    private var _centerX as Number;
    private var _centerY as Number;
    private var _gearFont as Graphics.FontDefinition;

    public function initialize() {
        DataField.initialize();

        currentState = 0;
        lastState = 0;
        _lastRearIndex = 0;
        _hasPreviousGearData = false;
        _rearGearText = "--";

        // Cache every display string so compute() only changes references.
        _gearText = [
            "--", "1", "2", "3", "4", "5", "6",
            "7", "8", "9", "10", "11", "12"
        ];

        // Allocate the complete double beep once outside the hot path.
        _doubleBeepOptions = {
            :toneProfile => [
                new Attention.ToneProfile(4000, 90),
                new Attention.ToneProfile(5000, 90)
            ]
        };

        _centerX = 0;
        _centerY = 0;
        _gearFont = Graphics.FONT_NUMBER_MILD;
    }

    public function onLayout(dc as Graphics.Dc) as Void {
        var width = dc.getWidth();
        var height = dc.getHeight();

        _centerX = width / 2;
        _centerY = height / 2;
        _gearFont = chooseGearFont(dc, width, height);
    }

    private function chooseGearFont(
        dc as Graphics.Dc,
        width as Number,
        height as Number
    ) as Graphics.FontDefinition {
        if ((Graphics.getFontHeight(Graphics.FONT_NUMBER_HOT) <= height) &&
            (dc.getTextWidthInPixels("12", Graphics.FONT_NUMBER_HOT) <= width)) {
            return Graphics.FONT_NUMBER_HOT;
        }
        if ((Graphics.getFontHeight(Graphics.FONT_NUMBER_MEDIUM) <= height) &&
            (dc.getTextWidthInPixels("12", Graphics.FONT_NUMBER_MEDIUM) <= width)) {
            return Graphics.FONT_NUMBER_MEDIUM;
        }
        if ((Graphics.getFontHeight(Graphics.FONT_NUMBER_MILD) <= height) &&
            (dc.getTextWidthInPixels("12", Graphics.FONT_NUMBER_MILD) <= width)) {
            return Graphics.FONT_NUMBER_MILD;
        }
        if ((Graphics.getFontHeight(Graphics.FONT_LARGE) <= height) &&
            (dc.getTextWidthInPixels("12", Graphics.FONT_LARGE) <= width)) {
            return Graphics.FONT_LARGE;
        }
        if ((Graphics.getFontHeight(Graphics.FONT_MEDIUM) <= height) &&
            (dc.getTextWidthInPixels("12", Graphics.FONT_MEDIUM) <= width)) {
            return Graphics.FONT_MEDIUM;
        }
        return Graphics.FONT_SMALL;
    }

    public function compute(info as Activity.Info) as Void {
        var frontIndex = info.frontDerailleurIndex;
        var rearIndex = info.rearDerailleurIndex;

        if (((frontIndex == 2) && ((rearIndex == 1) || (rearIndex == 2))) ||
            ((frontIndex == 1) && ((rearIndex == 11) || (rearIndex == 12)))) {
            currentState = 2;
        } else if (((frontIndex == 2) && (rearIndex == 3)) ||
            ((frontIndex == 1) && (rearIndex == 10))) {
            currentState = 1;
        } else {
            currentState = 0;
        }

        if ((rearIndex != null) && (rearIndex >= 1) && (rearIndex <= 12)) {
            _rearGearText = _gearText[rearIndex];
        } else {
            _rearGearText = _gearText[0];
        }

        var hasValidGearData =
            ((frontIndex == 1) || (frontIndex == 2)) &&
            (rearIndex != null) && (rearIndex >= 1) && (rearIndex <= 12);
        var shiftedFurtherIntoCrossChain =
            hasValidGearData &&
            (((frontIndex == 2) && (rearIndex < _lastRearIndex)) ||
            ((frontIndex == 1) && (rearIndex > _lastRearIndex)));

        // Preserve the yellow-boundary alert and also alert on every shift
        // farther into red. Entering red covers automatic rear compensation
        // during a chainring change even when the front and rear derailleur
        // updates arrive in separate compute() calls.
        if (_hasPreviousGearData &&
            (((currentState == 1) && (lastState == 0)) ||
            ((currentState == 2) &&
            ((lastState != 2) || shiftedFurtherIntoCrossChain)))) {
            Attention.playTone(_doubleBeepOptions);
        }

        lastState = currentState;
        if (hasValidGearData) {
            _lastRearIndex = rearIndex;
            _hasPreviousGearData = true;
        } else {
            _hasPreviousGearData = false;
        }
    }

    public function onUpdate(dc as Graphics.Dc) as Void {
        if (currentState == 2) {
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_RED);
        } else if (currentState == 1) {
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_YELLOW);
        } else {
            var backgroundColor = getBackgroundColor();
            if (backgroundColor == Graphics.COLOR_WHITE) {
                dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_WHITE);
            } else {
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
            }
        }

        dc.clear();
        dc.drawText(
            _centerX,
            _centerY,
            _gearFont,
            _rearGearText,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }
}
