// +--------------------------------------------------------------------------+
// | Project :    SwissMilitaryWatchface                                      |
// | Author  :    Simon Lievre (simon.lievre@gmail.com                        |
// | Licence :    GNU GPLv3                                                   |
// | Date    :    11/08/2018                                                  |
// +--------------------------------------------------------------------------+

using Toybox.Application;
using Toybox.WatchUi;
using Toybox.Time;
using Toybox.Communications;

// @class : SwissMilitaryWatchface
// @desc  :  Model (MVC). Application entry point
class SwissMilitaryWatchfaceApp extends Application.AppBase
{

    // @func  : initialize
    // @param :
    // @ret   :
    // @desc  : Initialize the application
    function initialize() {
        AppBase.initialize();
    }
    
    // @func  : onStart
    // @param : (State) application state
    // @ret   :
    // @desc  : Handles Start event
    function onStart(state) {
    }
    
    // @func  : onStop
    // @param : (State) application state
    // @ret   :
    // @desc  : Handles Stop event
    function onStop(state) {
    }
    
    // @func  : getInitialView
    // @param :
    // @ret   : (array) SwissMilitaryWatchfaceView
    // @desc  : Instanciate the view
    function getInitialView() {
        return [new SwissMilitaryWatchfaceView()];
    }

    // @func  : onSettingsChanged
    // @param : 
    // @ret   :
    // @desc  : Handles SettigsChanged event
    function onSettingsChanged() {
        WatchUi.requestUpdate();
    }
}
