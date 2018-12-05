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

var hasPartialUpdate;    // (Boolean) Stores if the device has partial updates or not

// @class : SwissMilitaryWatchfaceView
// @desc  :  View (MVC). Handles the display
class SwissMilitaryWatchfaceView extends Ui.WatchFace
{
    
    const TAIL_LENGTH = 30;         // (int) Tail length of the watch hands
    const HOUMIN_HAND_WIDTH = 10;   // (int) Width of the hour and the minute watch hands
    const SEC_HAND_TAIL_WIDTH = 4;  // (int) Tail width of the second-hand
    const SEC_HAND_TIP_WIDTH = 1;   // (int) Tip width of the second-hand
    const ARROW_HEIGHT = 5;         // (int) Arrow height of the hour and minute watch hands
    const PADDING = 2;              // (int) Padding of the hour and minute watch hands

    var isAwake;            // (boolean) Used as a flag. Watch awake or not
    var center;             // (Array)   Stores the center point ==> [x, y]
    var background;         // (Bitmap)  Watchface bitmap
    var logo;               // (Bitmap)  Logo bitmap
    var military;           // (Bitmap)  Logo military
    var fontIn;             // (Font) Font used for the numbers
    var fontOut;            // (Font) Font used for the numbers
    var fullRefresh;        // (Boolean) Used as a flag. Performs full screen refresh or not
    var backBuf;            // (BufferedBitmap) Background buffer
    var dateBuf;            // (BufferedBitmap) Date buffer
    var curClip;            // /?) Used to clip the area to refresh

    // @func  : initialize
    // @param :
    // @ret   :
    // @desc  : Initialize variables for this view
    function initialize() {
        WatchFace.initialize();
        fullRefresh = true;
        hasPartialUpdate = (Toybox.WatchUi.WatchFace has :onPartialUpdate);
    }
    
    // @func  : onLayout
    // @param : (DrawContext) dc
    // @ret   :
    // @desc  : Configure the layout of the watchface for this device
    function onLayout(dc) {
        
        // Load resources
        logo = Ui.loadResource(Rez.Drawables.logo);
        military = Ui.loadResource(Rez.Drawables.military);
        fontIn = Ui.loadResource(Rez.Fonts.smInside);
        fontOut = Ui.loadResource(Rez.Fonts.smBorder);
        
        // Buffers
        if(Toybox.Graphics has :BufferedBitmap) {
        
            backBuf = new Graphics.BufferedBitmap({
                :width=>dc.getWidth(),
                :height=>dc.getHeight(),
                :palette=> [
                    Graphics.COLOR_DK_RED,
                    0xC7DDA6,
                    Graphics.COLOR_BLACK,
                    Graphics.COLOR_WHITE
                ]
            });
            
            dateBuf = new Graphics.BufferedBitmap({
                :width=>dc.getWidth(),
                :height=>Graphics.getFontHeight(Graphics.FONT_XTINY)+2*PADDING
            });
            
        } else {
            backBuf = null;
        }
        
        curClip = null;
        isAwake = false;
        
        // Stores center
        center = [dc.getWidth()/2, dc.getHeight()/2];
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

            coords[i] = [center[0] + x, center[1] + y];
        }
        
        return coords;
    }

    // @func  : drawHouMinHand
    // @param : (DrawContext) dc; (int) angle; (int) handLength
    // @ret   : (Array) arrow
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
        dc.setColor(0xC7DDA6, 0xC7DDA6);
        dc.fillPolygon(rect);
        
        return arrow;
    }
    
    // @func  : getSecHandCoords
    // @param : (int) angle; (int) handLength
    // @ret   : (Array) coords
    // @desc  : return the second hand coordinates
    function getSecHandCoords(angle, handLength) {
    
        var secHand = [
            [-SEC_HAND_TAIL_WIDTH/2, TAIL_LENGTH],
            [-SEC_HAND_TIP_WIDTH/2, -handLength],
            [SEC_HAND_TIP_WIDTH/2, -handLength],
            [SEC_HAND_TAIL_WIDTH/2, TAIL_LENGTH]
        ];
        return transCoords(secHand, angle);
    }
    
    // @func  : drawSecHand
    // @param : (DrawContext) dc; (int) angle; (int) handLength
    // @ret   : 
    // @desc  : Draw the second-hand (polygon)
    function drawSecHand(dc, angle, handLength) { 
        
        // Transform the coordinates
        var coords = getSecHandCoords(angle, handLength);

        // Draw hand
        dc.setColor(Graphics.COLOR_DK_RED, Graphics.COLOR_DK_RED);
        dc.fillPolygon(coords);
    }
    
    // @func  : drawRotatedRectangle
    // @param : (DrawContext) dc; (Array) p; (int) alpha; (int) width; (int) height
    // @ret   : 
    // @desc  : Draw a rectangle rotated rotated by alpha radians (polygon)
    function drawRotatedRectangle(dc, p, alpha, width, height) {
        //  b---------c
        //  |         | height
        //  a----p----d
        //     width
        
        var a;
        var b;
        var c;
        var d;
        var rect;
        
        a = [p[0] - width/2 * Math.cos(alpha), p[1] - width/2 * Math.sin(alpha)];
        b = [a[0] + height * Math.cos(Math.PI/2 + alpha), a[1] + height * Math.sin((Math.PI/2) + alpha)];
        c = [b[0] + width * Math.cos(alpha), b[1] + width * Math.sin(alpha)];
        d = [a[0] + width * Math.cos(alpha), a[1] + width * Math.sin(alpha)];
        
        rect = [a, b, c, d];
        dc.setColor(0xC7DDA6, 0xC7DDA6);
        dc.fillPolygon(rect);
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.drawLine(a[0], a[1], b[0], b[1]);
        dc.drawLine(b[0], b[1], c[0], c[1]);
        dc.drawLine(c[0], c[1], d[0], d[1]);
        dc.drawLine(d[0], d[1], a[0], a[1]);
    }
    
    // @func  : drawNumbers
    // @param : (DrawContext) dc
    // @ret   : 
    // @desc  : Draw the hour numbers
    function drawNumbers(dc) {
    
        var width = dc.getWidth();
        var height = dc.getHeight();
        
        var r = width/2;
        var rOut = r - PADDING;
        var rIn = rOut - 30;
        var rInIn = rIn - 30;
        
        // Loop through each 5 minute block and draw tick marks.
        for (var i = 0; i < 12; i++) {
        
            var alpha = i * (Math.PI/6);
            
            if(i != 9){
                
                dc.setColor(0xC7DDA6, Graphics.COLOR_TRANSPARENT);
                dc.drawText(r + rIn * Math.cos(alpha)-dc.getTextWidthInPixels(""+(i+3)%12, fontIn)/2, r + rIn * Math.sin(alpha)-Graphics.getFontHeight(fontIn)/2, fontIn, (i+3)%12, Graphics.TEXT_JUSTIFY_LEFT);
                dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
                dc.drawText(r + rIn * Math.cos(alpha)-dc.getTextWidthInPixels(""+(i+3)%12, fontOut)/2, r + rIn * Math.sin(alpha)-Graphics.getFontHeight(fontOut)/2 , fontOut, (i+3)%12, Graphics.TEXT_JUSTIFY_LEFT);
                
                //dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
                //dc.drawText(r + rInIn * Math.cos(alpha)-dc.getTextWidthInPixels(""+(i+15)%24, fontOut)/2, r + rIn * Math.sin(alpha)-Graphics.getFontHeight(fontOut)/2 , fontOut, (i+3)%12, Graphics.TEXT_JUSTIFY_LEFT);
            }
        }
    }
    
    // @func  : drawHashMarks
    // @param : (DrawContext) dc
    // @ret   : 
    // @desc  : Draw the hash marks
    function drawHashMarks(dc) {
    
        var width = dc.getWidth();
        var height = dc.getHeight();
        var sX;
        var sY;
        var eX;
        var eY;
        
        var r = width/2;
        var rOut = r - PADDING;
        var rIn = rOut - 7;
        
        // Loop through each 5 minute block and draw tick marks.
        for (var i = 0; i <= 11 * Math.PI / 6; i += (Math.PI / 6)) {
            
            // Draw major ticks (rotated rectangles)
            var p = [r + rOut * Math.cos(i), r + rOut * Math.sin(i)];
            drawRotatedRectangle(dc, p, i + (Math.PI/2), 10, 7);
            
           // Loop through each minute block within a 5 min block.
           for (var j=i+(Math.PI / 30); j<i+(Math.PI / 6); j+=(Math.PI / 30)) {
           
               sY = r + rIn * Math.sin(j);
               eY = r + rOut * Math.sin(j);
               sX = r + rIn * Math.cos(j);
               eX = r + rOut * Math.cos(j);
               dc.drawLine(sX, sY, eX, eY);
           }
        }
    }

    // @func  : onUpdate
    // @param : (DrawContext) dc
    // @ret   : 
    // @desc  : Handles update event
    function onUpdate(dc) {
    
        var clockTime = System.getClockTime();  // (int) System time
        var minuteHandAngle;                    // (int) Minute angle
        var hourHandAngle;                      // (int) Hour angle
        var secondHandAngle;                    // (int) Second angle
        var width;                              // (int) Screen width
        var height;                             // (int) Screen height
        var targetDc = null;                    // (DrawContext) Where to draw the elements

        // We always want to refresh the full screen when we get a regular onUpdate call.
        fullRefresh = true;

        if(null != backBuf) {
            dc.clearClip();
            curClip = null;
            targetDc = backBuf.getDc();
        } else {
            targetDc = dc;
        }
        
        width = targetDc.getWidth();
        height = targetDc.getHeight();
        
        // Draw the background
        targetDc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE);
        targetDc.fillRectangle(0, 0, dc.getWidth(), dc.getHeight());
        targetDc.drawBitmap(width/2-(logo.getWidth()/2), 0.15*height-(logo.getHeight()/2), logo);
        targetDc.drawBitmap(width/2-(military.getWidth()/2), 0.35*height-(military.getHeight()/2), military);
        
        // Draw hash marks
        drawHashMarks(targetDc);
        drawNumbers(targetDc);
        
        // Draw the hour hand. Convert it to minutes and compute the angle.
        hourHandAngle = (((clockTime.hour % 12) * 60) + clockTime.min);
        hourHandAngle = hourHandAngle / (12 * 60.0);
        hourHandAngle = hourHandAngle * Math.PI * 2;
        drawHouMinHand(targetDc, hourHandAngle, 70);

        // Draw the minute hand.
        minuteHandAngle = (clockTime.min / 60.0) * Math.PI * 2;
        drawHouMinHand(targetDc, minuteHandAngle, 95);
        
        // Draw the arbor in the center of the screen.
        targetDc.setColor(Graphics.COLOR_DK_RED, Graphics.COLOR_DK_RED);
        targetDc.fillCircle(center[0], center[1], 6);
        targetDc.setColor(Graphics.COLOR_BLACK,Graphics.COLOR_BLACK);
        targetDc.drawCircle(center[0], center[1], 6);
        
        // Draw the date
        if( null != dateBuf ) {
        
            var dateDc = dateBuf.getDc();

            //Draw the background image buffer into the date buffer to set the background
            dateDc.drawBitmap(0, -height/2, backBuf);

            //Draw the date string into the buffer.
            dateDc.drawRectangle(2*width/3, 0, 20+PADDING, Graphics.getFontHeight(Graphics.FONT_XTINY)+PADDING);
            drawDateString(dateDc, 2*width/3+PADDING, 0);
        }
        
        // Output the offscreen buffers to the main display if required.
        drawBackground(dc);
        
         if( hasPartialUpdate ) {
            // If this device supports partial updates and they are currently
            // allowed run the onPartialUpdate method to draw the second hand.
            onPartialUpdate( dc );
        } else if ( isAwake ) {
            // Otherwise, if we are out of sleep mode, draw the second hand
            // directly in the full update method.
            secondHandAngle = (clockTime.sec / 60.0) * Math.PI * 2;
            drawSecHand(dc, secondHandAngle, 100);
        }

        fullRefresh = false;
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
    
     // Handle the partial update event
    function onPartialUpdate( dc ) {
        // If we're not doing a full screen refresh we need to re-draw the background
        // before drawing the updated second hand position. Note this will only re-draw
        // the background in the area specified by the previously computed clipping region.
        if(!fullRefresh) {
            drawBackground(dc);
        }

        var clockTime = System.getClockTime();
        var secAngle = (clockTime.sec / 60.0) * Math.PI * 2;
        var secHand = getSecHandCoords(secAngle, 100);

        // Update the cliping rectangle to the new location of the second hand.
        curClip = getBoundingBox( secHand );
        var bboxWidth = curClip[1][0] - curClip[0][0] + 1;
        var bboxHeight = curClip[1][1] - curClip[0][1] + 1;
        dc.setClip(curClip[0][0], curClip[0][1], bboxWidth, bboxHeight);
        
        dc.setColor(Graphics.COLOR_DK_RED, Graphics.COLOR_DK_RED);
        dc.fillPolygon(secHand);
    }

    // Compute a bounding box from the passed in points
    function getBoundingBox( points ) {
        var min = [9999,9999];
        var max = [0,0];

        for (var i = 0; i < points.size(); ++i) {
            if(points[i][0] < min[0]) {
                min[0] = points[i][0];
            }

            if(points[i][1] < min[1]) {
                min[1] = points[i][1];
            }

            if(points[i][0] > max[0]) {
                max[0] = points[i][0];
            }

            if(points[i][1] > max[1]) {
                max[1] = points[i][1];
            }
        }

        return [min, max];
    }

    // Draw the watch face background
    // onUpdate uses this method to transfer newly rendered Buffered Bitmaps
    // to the main display.
    // onPartialUpdate uses this to blank the second hand from the previous
    // second before outputing the new one.
    function drawBackground(dc) {
        var width = dc.getWidth();
        var height = dc.getHeight();

        //If we have an offscreen buffer that has been written to
        //draw it to the screen.
        if( null != backBuf ) {
            dc.drawBitmap(0, 0, backBuf);
        }

        // Draw the date
        if( null != dateBuf ) {
            // If the date is saved in a Buffered Bitmap, just copy it from there.
            dc.drawBitmap(0, height/2, dateBuf);
        } else {
            // Otherwise, draw it from scratch.
            dc.drawRectangle(2*width/3, height/2, 20+PADDING, Graphics.getFontHeight(Graphics.FONT_XTINY)+PADDING);
            drawDateString(dc, 2*width/3+PADDING, height/2);
        }
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
