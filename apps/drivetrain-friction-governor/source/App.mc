import Toybox.Application;
import Toybox.WatchUi;

class DrivetrainFrictionGovernorApp extends Application.AppBase {
    public function initialize() {
        AppBase.initialize();
    }

    public function getInitialView() as [WatchUi.Views] or [WatchUi.Views, WatchUi.InputDelegates] {
        return [new DrivetrainFrictionGovernorView()];
    }
}

function getApp() as DrivetrainFrictionGovernorApp {
    return Application.getApp() as DrivetrainFrictionGovernorApp;
}
