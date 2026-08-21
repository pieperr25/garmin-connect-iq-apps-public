using Toybox.Application;

class WindFieldApp extends Application.AppBase {
    function initialize() {
        AppBase.initialize();
    }

    function getInitialView() {
        return [new WindFieldView()];
    }
}
