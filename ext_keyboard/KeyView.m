#import <CoreText/CoreText.h>
#import "KeyView.h"
#import "KeyMap.h"
#import "KeyBoard.h"
#import "KeyDrawer.h"


@implementation KeyView
{

    KeyBoard* keyBoard;         // keyboard state and drawing

    CGPoint moveOffset;         // movement offset between two touches
    CGPoint lastTouchPos;       // last touch position for swipes

    UITouch* sentTouch;         // touch already sent in
    NSDate* faultTime;          // last fault date
    NSMutableArray* touches;    // touch queue
    NSUserDefaults* defaults;   // settings
    NSNotificationCenter *center;

    int touchMoved;             // indicates that touch is moved, no key send is needed

}


- ( id ) init
{

    self = [ super init ];
    
    defaults = [ [ NSUserDefaults alloc ] initWithSuiteName : @"group.milgra.keyboard" ];

    center = [ NSNotificationCenter defaultCenter ];
    
    touches = [ [ NSMutableArray alloc ] init ];

    keyBoard = [ [ KeyBoard alloc ] initWithView : self  ];

    self.multipleTouchEnabled = YES;

    return self;
    
}


- ( void ) drawRect : ( CGRect ) rect
{

    [ keyBoard draw ];

}


- ( void ) moveCursorX : ( float ) dx
           Y : ( float ) dy
{

    moveOffset.x += dx;
    moveOffset.y += dy;
    
    CGPoint keysize = [ KeyDrawer getKeySize ];

    if ( fabs( moveOffset.x ) > keysize.x / 2.0 )
    {
        touchMoved = 1;

        NSInteger jump = ( long ) ( moveOffset.x / ( keysize.x / 2.0 ) );
        
        [ center postNotificationName : @"control"
                 object : @{ @"name" : @"adjust" , @"value" : [ NSNumber numberWithInteger : jump ] } ];

        if ( moveOffset.x > 0.0 ) moveOffset.x -= keysize.x / 2.0;
        if ( moveOffset.x < 0.0 ) moveOffset.x += keysize.x / 2.0;
    }

    if ( fabs( moveOffset.y ) > keysize.y )
    {
        touchMoved = 1;

        int sign = 1;
        if ( moveOffset.y < 0.0 ) sign = -1;
        NSInteger jump = sign * ( long ) ( [ [ UIScreen mainScreen ] bounds].size.width / ( keysize.x / 2.0 ) );

        [ center postNotificationName : @"control"
                 object : @{ @"name" : @"adjust" , @"value" : [ NSNumber numberWithInteger : jump ] } ];
        
        if ( moveOffset.y > 0.0 ) moveOffset.y -= keysize.x;
        if ( moveOffset.y < 0.0 ) moveOffset.y += keysize.x;
    }
    
}


- ( void ) sendTouch : ( UITouch* ) pTouch
{

    CGPoint touchPos = [ pTouch locationInView : self ];

    lastTouchPos = touchPos;
    sentTouch = pTouch;

    BOOL success = [ keyBoard touchStarted : touchPos ];
    
    if ( success == NO )
    {
        faultTime = [ NSDate date ];
    }
    else
    {
        faultTime = nil;
    }
    
}


- ( void ) touchesBegan : ( NSSet* ) pTouches
           withEvent : ( UIEvent* ) event
{

    if ( faultTime != nil )
    {
    
        float timeout = [ defaults floatForKey : @"timeout" ];
        NSTimeInterval delta = [ [ NSDate date ] timeIntervalSinceDate : faultTime ];
        
        if ( delta < timeout ) return;

    }
    
    moveOffset.x = 0.0;
    moveOffset.y = 0.0;

    UITouch* anyTouch = [ pTouches anyObject ];

    if ( [ touches count ] == 0 )
    {
        [ touches addObject : anyTouch ];
        [ self sendTouch : anyTouch ];
    }
    else [ touches addObject : anyTouch ];

}


- ( void ) touchesMoved : ( NSSet* ) pTouches
           withEvent : ( UIEvent* ) event
{

    if ( [ touches count ] > 0 )
    {

        for ( UITouch* oneTouch in pTouches )
        {

            if ( touches[ 0 ] == oneTouch )
            {
            
                CGPoint point = [ oneTouch locationInView : self ];

                float dx = point.x - lastTouchPos.x;
                float dy = point.y - lastTouchPos.y;

                CGPoint keysize = [ KeyDrawer getKeySize ];

                if ( fabs( dx ) > keysize.x ||
                     fabs( dy ) > keysize.x )
                {
                    dx = 0.0;
                    dy = 0.0;
                }

                lastTouchPos = point;

                [ self moveCursorX : dx  Y : dy ];
            }
        
        }
        
    }

}


- ( void ) touchesEnded : ( NSSet* ) pTouches
           withEvent : ( UIEvent* ) event
{

    for ( int index = 0 ;
              index < [ touches count ] ;
              index++ )
    {

        UITouch* touch = touches[ index ];

        if ( [ pTouches containsObject : touch ] )
        {

            if ( touch != sentTouch ) [ self sendTouch : touch ];
        
            // stop touch in keyboard

            [ keyBoard stopDelete ];

            if ( touchMoved == 0 ) [ keyBoard touchEnded ];

            touchMoved = 0;

        }
        else break;
    
    }
    
    [ touches removeObjectsInArray : [ pTouches allObjects ] ];
    
}


- ( void ) touchesCancelled : ( NSSet* ) pTouches
           withEvent : ( UIEvent* ) event
{

    [ touches removeObjectsInArray : pTouches.allObjects ];

}


- ( float ) calculateHeightForPortraitWidth : ( float ) width
{

    return [ keyBoard heightForPortrait : width ];
    
}


- ( float ) calculateHeightForLandscapeWidth : ( float ) width
{

    return [ keyBoard heightForLandscape : width ];

}


@end
