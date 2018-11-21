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
    
    const TAIL_LENGTH = 30;         // (int) Tail length of the watch hands
    const HOUMIN_HAND_WIDTH = 10;   // (int) Width of the hour and the minute watch hands
    const SEC_HAND_TAIL_WIDTH = 2;  // (int) Tail width of the second-hand
    const SEC_HAND_TIP_WIDTH = 1;   // (int) Tip width of the second-hand
    const ARROW_HEIGHT = 5;         // (int) Arrow height of the hour and minute watch hands
    const PADDING = 2;              // (int) Padding of the hour and minute watch hands

    var isAwake;            // (boolean) Used as a flag. Watch awake or not
    var screenCenterPoint;  // (Array)   Stores the center point ==> [x, y]
    var background;         // (Bitmap)  Watchface bitmap

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
        
        // Draw the background
        background = Ui.loadResource(Rez.Drawables.background);
        
        // Stores center
        screenCenterPoint = [dc.getWidth()/2, dc.getHeight()/2];
    }
    
    // @func  : transCoords
    // @param : (Array) coords; (int) angle
    // @ret   : (Array) coords
    // @desc  : Update the coordinates depending on an angle and the center point
    function transCoords(coords, angle) {
    
        var cos = Math.cos(angle);
        var sin = Math.sin(angle);
        
        for (var i=0; i < coords.size(); i++) {
            var x = (coords[i][0] * cos) - (coords[i][1] * sin) + 0.5;
            var y = (coords[i][0] * sin) + (coords[i][1] * cos) + 0.5;

            coords[i] = [screenCenterPoint[0] + x, screenCenterPoint[1] + y];
        }
        
        return coords;
    }

    // @func  : drawHouMinHand
    // @param : (DrawContext) dc; (int) angle; (int) handLength
    // @ret   : 
    // @desc  : Draw a watch hand (polygon)
    function drawHouMinHand(dc, angle, handLength) {
        
        // What I want to draw:
        //
        //   /\
        //  /  \    ARROW_HEIGHT
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
        // |    |   TAIL_LENGTH
        // +----+
        //  HOUMIN_HAND_WIDTH
        
        // Coordinates
        var arrow = [
            [-HOUMIN_HAND_WIDTH/2, TAIL_LENGTH],
            [-HOUMIN_HAND_WIDTH/2, -handLength],
            [0, -handLength-ARROW_HEIGHT],
            [HOUMIN_HAND_WIDTH/2, -handLength],
            [HOUMIN_HAND_WIDTH/2, TAIL_LENGTH]
        ];
        var rect = [
            [-HOUMIN_HAND_WIDTH/2+PADDING, -TAIL_LENGTH],
            [-HOUMIN_HAND_WIDTH/2+PADDING, -handLength+PADDING],
            [HOUMIN_HAND_WIDTH/2-PADDING, -handLength+PADDING],
            [HOUMIN_HAND_WIDTH/2-PADDING, -TAIL_LENGTH]
        ];
        
        // Transform the coordinates
        arrow = transCoords(arrow, angle);
        rect = transCoords(rect, angle);
        
        // Draw hand
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.fillPolygon(arrow);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE);
        dc.fillPolygon(rect);
    }
    
    // @func  : drawSecHand
    // @param : (DrawContext) dc; (int) angle; (int) handLength
    // @ret   : 
    // @desc  : Draw the second-hand (polygon)
    function drawSecHand(dc, angle, handLength) {
        
        // Coordinates
        var coords = [
            [-SEC_HAND_TAIL_WIDTH/2, TAIL_LENGTH],
            [-SEC_HAND_TIP_WIDTH/2, -handLength],
            [SEC_HAND_TIP_WIDTH/2, -handLength],
            [SEC_HAND_TAIL_WIDTH/2, TAIL_LENGTH]
        ];
        
        // Transform the coordinates
        coords = transCoords(coords, angle);

        // Draw hand
        dc.setColor(Graphics.COLOR_DK_RED, Graphics.COLOR_DK_RED);
        dc.fillPolygon(coords);
    }

    // @func  : onUpdate
    // @param : (DrawContext) dc
    // @ret   : 
    // @desc  : Handles update event
    function onUpdate(dc) {
    
        var clockTime = System.getClockTime();  // (int)   System time
        var minuteHandAngle;                    // (int)   Minute angle
        var hourHandAngle;                      // (int)   Hour angle
        var secondHandAngle;                    // (int)   Second angle
        
        // Clear the screen
        dc.clear();
        
        // Draw the background image
        dc.drawBitmap(0, 0, background);
        
        // Draw the hour hand. Convert it to minutes and compute the angle.
        hourHandAngle = (((clockTime.hour % 12) * 60) + clockTime.min);
        hourHandAngle = hourHandAngle / (12 * 60.0);
        hourHandAngle = hourHandAngle * Math.PI * 2;
        drawHouMinHand(dc, hourHandAngle, 70);

        // Draw the minute hand.
        minuteHandAngle = (clockTime.min / 60.0) * Math.PI * 2;
        drawHouMinHand(dc, minuteHandAngle, 95);
        
        // Draw the second hand if awake
        if(isAwake){
            secondHandAngle = (clockTime.sec / 60.0) * Math.PI * 2;
            drawSecHand(dc, secondHandAngle, 100);
        }
        
        // Draw the arbor in the center of the screen.
        dc.setColor(Graphics.COLOR_DK_RED, Graphics.COLOR_DK_RED);
        dc.fillCircle(screenCenterPoint[0], screenCenterPoint[1], 5);
        dc.setColor(Graphics.COLOR_BLACK,Graphics.COLOR_BLACK);
        dc.drawCircle(screenCenterPoint[0], screenCenterPoint[1], 5);
        
        // Draw the date
        drawDateString(dc, 185, 108);
    }

    // @func  : drawDateString
    // @param : (DeviceContext) dc; (int) x; (int) y
    // @ret   : 
    // @desc  : Draw the date
    function drawDateString(dc, x, y) {
        var info = Gregorian.info(Time.now(), Time.FORMAT_LONG);
        var dayStr = Lang.format("$1$", [info.day]);

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y, Graphics.FONT_XTINY, dayStr, Graphics.TEXT_JUSTIFY_LEFT);
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
