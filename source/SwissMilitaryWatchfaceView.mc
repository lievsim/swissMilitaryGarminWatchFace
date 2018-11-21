// +--------------------------------------------------------------------------+
// | Project :    SwissMilitaryWatchface                                      |
// | Author  :    Simon Lievre (simon.lievre@gmail.com                        |
// | Licence :    GNU GPLv3                                                   |
// | Date    :    11/08/2018                                                  |
// +--------------------------------------------------------------------------+

using Toybox.Graphics;
using Toybox.Lang;
using Toybox.Math;
using Toybox.System;
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.WatchUi as Ui;
using Toybox.Application;

// @class : SwissMilitaryWatchfaceView
// @desc  :  View (MVC). Handles the display
class SwissMilitaryWatchfaceView extends Ui.WatchFace
{

    var isAwake;            // (boolean) Used as a flag. Watch awake or not
    var dateBuffer;         // (Buffer)  Used to write the date
    var screenCenterPoint;  // (array)   Stores the center point ==> [x, y]
    var background;         // (ressouce) Background image

    // @func  : initialize
    // @param :
    // @ret   :
    // @desc  : Initialize variables for this view
    function initialize() {
        WatchFace.initialize();
    }
    
    // @func  : onLayout
    // @param : (DrawContext) dc
    // @ret   :
    // @desc  : Configure the layout of the watchface for this device
    function onLayout(dc) {
        
        background = Ui.loadResource(Rez.Drawables.background);
        
        // Allocate the buffer used for writting the date
        if(Toybox.Graphics has :BufferedBitmap) {
            dateBuffer = new Graphics.BufferedBitmap({
                :width=>dc.getWidth(),
                :height=>Graphics.getFontHeight(Graphics.FONT_MEDIUM)
            });
        }
        
        screenCenterPoint = [dc.getWidth()/2, dc.getHeight()/2];
    }

    // @func  : generateHandCoordinates
    // @param : (array) centerPoint; (int) angle; (int) handLength; (int) tailLength; (int) arrowLength; (int) width
    // @ret   : (dict) watchHand ==> The list of polygons to draw
    // @desc  : Generates a list of polygons for a watch hand
    function generateHandCoordinates(centerPoint, angle, handLength, tailLength, width) {
        
        // What I want to draw:
        //
        //   /\
        //  /  \    arrowLength
        // /    \
        //--------------------
        // | ++ |
        // | || |   handLength
        // | || |
        // | || |   ==> rectangle inside
        // | || |
        // | || |
        // | ++ |
        // |    |
        // |    |
        //-------------------- center
        // |    |
        // |    |   tailLength
        // +----+
        
        // Map out the coordinates of the watch hand
        var coords = [[-(width / 2), tailLength], [-(width / 2), -handLength], [width / 2, -handLength], [width / 2, tailLength]];
        var result = new [4];
        var cos = Math.cos(angle);
        var sin = Math.sin(angle);

        // Transform the coordinates
        for (var i = 0; i < 4; i += 1) {
            var x = (coords[i][0] * cos) - (coords[i][1] * sin) + 0.5;
            var y = (coords[i][0] * sin) + (coords[i][1] * cos) + 0.5;

            result[i] = [centerPoint[0] + x, centerPoint[1] + y];
        }

        return result;
    }

    // @func  : onUpdate
    // @param : (DrawContext) dc
    // @ret   : 
    // @desc  : Handles update event
    function onUpdate(dc) {
    
        var width = dc.getWidth();              // (int)   Screen width
        var height = dc.getHeight();            // (int)   Screen height
        var clockTime = System.getClockTime();  // (int)   System time
        var minuteHandAngle;                    // (int)   Minute angle
        var hourHandAngle;                      // (int)   Hour angle
        var watchHand;                          // (array) Used to draw a watch
                                                //         hand
        
        // Draw the background
        dc.drawBitmap(0, 0, background);
        
        //Use white to draw the hour and minute hands
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);

        // Draw the hour hand. Convert it to minutes and compute the angle.
        hourHandAngle = (((clockTime.hour % 12) * 60) + clockTime.min);
        hourHandAngle = hourHandAngle / (12 * 60.0);
        hourHandAngle = hourHandAngle * Math.PI * 2;

        dc.fillPolygon(generateHandCoordinates(screenCenterPoint, hourHandAngle, 40, 0, 3));

        // Draw the minute hand.
        minuteHandAngle = (clockTime.min / 60.0) * Math.PI * 2;
        dc.fillPolygon(generateHandCoordinates(screenCenterPoint, minuteHandAngle, 70, 0, 2));
        
        // Draw the arbor in the center of the screen.
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_LT_GRAY);
        dc.fillCircle(width / 2, height / 2, 7);
        dc.setColor(Graphics.COLOR_BLACK,Graphics.COLOR_BLACK);
        dc.drawCircle(width / 2, height / 2, 7);
        
        // Draw the date
        drawDateString(dc, 196, 110);
        
    }

    // @func  : drawDateString
    // @param : (DeviceContext) dc; (int) x; (int) y
    // @ret   : 
    // @desc  : Draw the date
    function drawDateString(dc, x, y) {
        var info = Gregorian.info(Time.now(), Time.FORMAT_LONG);
        var dayStr = Lang.format("$1$", [info.day]);

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y, Graphics.FONT_XTINY, dayStr, Graphics.TEXT_JUSTIFY_CENTER);
    }

    // @func  : onEnterSleep
    // @param : 
    // @ret   : 
    // @desc  : Handles EnterSleep event
    function onEnterSleep() {
        isAwake = false;
        Ui.requestUpdate();
    }

    // @func  : onEnterSleep
    // @param : 
    // @ret   : 
    // @desc  : Handles ExitSleep event
    function onExitSleep() {
        isAwake = true;
    }
    
}
