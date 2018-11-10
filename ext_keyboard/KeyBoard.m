#import <AVKit/AVKit.h>
#import "KeyMap.h"
#import "KeyBoard.h"
#import "KeyDrawer.h"


@implementation KeyBoard
{

    BOOL faultState;            // keybaord is in faulty press state
    BOOL shiftPressed;
    BOOL capsPressed;

    int playError;              // indicate if error sound has already played

    NSInteger pageIndex;        // page index
    NSInteger accIndex;         // accent ribbon index
    
    CGPoint touchPos;
    CGPoint tapPos;

    UIView* view;
    NSDate* shiftPressTime;     // last shift press date
    NSTimer* delTimer;          // backspace timer repeat
    NSString* actualGlyph;
    KeyDrawer* keyDrawer;
    NSMutableString* keymap;    // current keymap of keyview
    
    NSUserDefaults* defaults;
    NSNotificationCenter* center;

}


- ( id ) initWithView : ( UIView* ) pView
{
    self = [ super init ];

    tapPos = ( CGPoint ) { -50.0 , -50.0 };

    view = pView;
    center = [ NSNotificationCenter defaultCenter ];
    defaults = [ [ NSUserDefaults alloc ] initWithSuiteName : @"group.milgra.keyboard" ];
    keyDrawer = [ [ KeyDrawer alloc ] init ];

    return self;
}


- ( void ) draw
{

    accIndex = [ defaults integerForKey : @"accentIndex" ];

    keymap = [ KeyMap generateKeymapWithPage : pageIndex
                      accent : accIndex ];

    float strictness = [ defaults floatForKey : @"strictness" ];

    [ keyDrawer resetWithContext : UIGraphicsGetCurrentContext( )
                strictness : strictness
                accent : accIndex
                view : view ];
    
    for ( int index = 0 ;
              index < keymap.length ;
              index++ )
    {
    
        NSString* letter = [ keymap substringWithRange : NSMakeRange( index, 1) ];

        if ( [ letter isEqualToString : @" " ] ) // line start, calculate position
        {
            [ keyDrawer gotoNextLineFromIndex : index
                        keyMap : keymap
                        view : view ];

        }
        else
        {
            if ( [ letter isEqualToString : @"p" ] ||
                 [ letter isEqualToString : @"r" ] )  // paging
            {

                NSString* p2string = [ defaults objectForKey : @"p2string" ];
                NSString* acstring = [ defaults objectForKey : @"acstring" ];

                [ keyDrawer drawPagingButtonForLetter : letter
                            fault : faultState
                            pageIndex : pageIndex
                            accIndex : accIndex
                            pageString : p2string
                            accString : acstring ];
            }
            else if ( [ letter isEqualToString : @"n" ] ||
                      [ letter isEqualToString : @"e" ] ) // next
            {
                [ keyDrawer drawNextEnterButtonForLetter : letter
                            fault : faultState ];
            }
            else if ( [ letter isEqualToString : @"h" ] )  // shift
            {
                [ keyDrawer drawShiftFault : faultState
                            shift : shiftPressed
                            caps : capsPressed ];
            }
            else if ( [ letter isEqualToString : @"b" ] ) // backspace
            {
                [ keyDrawer drawDelFault : faultState ];
            }
            else if ( [ letter isEqualToString : @"s" ] ) // space
            {
                [ keyDrawer drawSpace ];
            }
            else
            {
                [ keyDrawer drawGlyph : letter
                            fault : faultState
                            actualGlyph : actualGlyph
                            touchPos : touchPos ];
            }
            
            [ keyDrawer storeKeyAtIndex : index ];
        
        }

    }
    
    [ keyDrawer drawTipFault : faultState
                tapPos : tapPos
                height : view.frame.size.height ];
}


- ( void ) sendKey
{

    if ( [ actualGlyph isEqualToString : @"h" ] )
    {
        float delta = 1.0;
        if ( shiftPressTime != nil ) delta = [ [ NSDate date ] timeIntervalSinceDate : shiftPressTime ];

        if ( capsPressed == 1 )
        {
            capsPressed = 0;
            shiftPressed = 0;
        }
        else
        {
            if ( delta < 0.2 )
            {
                capsPressed = 1;
                shiftPressed = 1;
            }
            else
            {
                shiftPressed = 1 - shiftPressed;
                capsPressed = 0;
            }
        }

        shiftPressTime = [NSDate date];
    }
    else if ( [actualGlyph isEqualToString : @"p"] )
    {
        pageIndex = 1 - pageIndex;
    }
    else if ( [actualGlyph isEqualToString : @"r"] )
    {
        NSString* acstring = [ defaults objectForKey : @"acstring" ];
        if ( accIndex == 0 )
        {
            accIndex = 1;
        }
        else if ( accIndex == 1 )
        {
            if ( acstring.length > 10 ) accIndex = 2;
            else accIndex = 0;
        }
        else if ( accIndex == 2 )
        {
            accIndex = 0;
        }
        
        [ center postNotificationName : @"control"
                 object : @{ @"name" : @"resize" } ];
        
        [ defaults setInteger : accIndex
                   forKey : @"accentIndex" ];
        
        [ defaults synchronize ];
    }
    else if ( [actualGlyph isEqualToString : @"n"] )
    {
        [ center postNotificationName : @"control"
                 object : @{ @"name" : @"next" } ];
    }
    else if ( [actualGlyph isEqualToString: @"e"] )
    {
        [ center postNotificationName : @"control"
                 object : @{ @"name" : @"insert" , @"letter" : @"\n" } ];
    }
    else if ( [actualGlyph isEqualToString : @"s"] )
    {
        [ center postNotificationName : @"control"
                 object : @{ @"name" : @"insert" , @"letter" : @" " } ];
    }
    else if ( [actualGlyph isEqualToString : @"b"] )
    {
        // do nothing with backspace, the timer & touch start will handle it
    }
    else
    {
        NSString* string = actualGlyph;
        
        if ( shiftPressed == 0 ) string = [ actualGlyph lowercaseString ];
        
        [ center postNotificationName: @"control"
                 object : @{ @"name" : @"insert" , @"letter" : string } ];
        
        if ( capsPressed == 0 && shiftPressed == 1 ) shiftPressed = 0;
    }

    [ view setNeedsDisplay ];

}


- ( BOOL ) touchStarted : ( CGPoint ) position
{

    touchPos = position;
    tapPos = CGPointMake( touchPos.x , view.frame.size.height - touchPos.y );

    struct keysearchinfo info = [ keyDrawer keyIndexForPosition : touchPos
                                            keyMap : keymap ];

    // check backspace for autorepeat

    if ( info.pick > -1 )
    {
        actualGlyph = [ keymap substringWithRange : NSMakeRange( info.pick , 1 ) ];
        
        CGPoint keysize = [ KeyDrawer getKeySize ];

        char letgo = 0;

        NSString* prevletter = nil;
        NSString* nextletter = nil;

        if ( info.pick > 0 ) prevletter = [ keymap substringWithRange : NSMakeRange( info.pick - 1 , 1 ) ];
        if ( info.pick < keymap.length - 1 ) nextletter = [ keymap substringWithRange : NSMakeRange( info.pick + 1 , 1 ) ];

        // check dead zones

        if ( [ @"hbnse" containsString : actualGlyph ] ) letgo = 1;  // let special keys go
        
        if ( prevletter != nil &&
             [ prevletter isEqualToString : @" " ] &&
             info.minx < -keysize.x / 2.0 ) letgo = 1; // let left edge keys go
        
        if ( nextletter != nil &&
             [ nextletter isEqualToString : @" " ] &&
             info.minx >  keysize.x / 2.0 ) letgo = 1; // let right edge keys go
        
        if ( fabs(info.minx) < keysize.x / 2.0 &&
             fabs(info.miny) < keysize.y / 2.0 ) letgo = 1; // let touched keys go

        if ( [ actualGlyph isEqualToString : @"b" ] )
        {
            [ center postNotificationName: @"control"
                     object : @{ @"name" : @"delete" } ];

            delTimer = [ NSTimer scheduledTimerWithTimeInterval : .3
                                 target : self
                                 selector : @selector(startDelete)
                                 userInfo : NULL
                                 repeats : YES ];
        }
        else
        {

            if ( letgo == 0 )
            {
                faultState = YES;
                actualGlyph = nil;
                playError = 1;
                return NO;
            }
            else
            {
                faultState = NO;
            }
        }
    }
    else actualGlyph = nil;
    
    return YES;

}


- ( void ) touchEnded
{

    if ( actualGlyph != nil )
    {
    
        [ self sendKey ];
        AudioServicesPlaySystemSound( 1104 );
        
        view.backgroundColor = [ UIColor whiteColor ];
        [view setNeedsDisplay];
        
    }
    else
    {
    
        if ( playError == 1 ) AudioServicesPlaySystemSound( 1057 );
        playError = 0;
        view.backgroundColor = [ UIColor lightGrayColor ];
        [view setNeedsDisplay];
        
    }

}


- ( void ) delete
{

    [ center postNotificationName : @"control"
             object : @{ @"name" : @"delete" } ];
    
}


- ( void) startDelete
{

    if ( delTimer != nil )
    {
        [ delTimer invalidate ];
        
        delTimer = [ NSTimer scheduledTimerWithTimeInterval : .065
                             target : self
                             selector : @selector(delete)
                             userInfo : NULL
                             repeats : YES ];
    }
    
}


- ( void ) stopDelete
{

    if ( delTimer != nil )
    {
        [ delTimer invalidate ];
        delTimer = nil;
        return;
    }

}


- ( float ) heightForPortrait : ( float ) width
{
    
    float sizetouse = width;

    float keywidth = sizetouse / 10.0;
    float keyheight = keywidth * 1.2;
    
    int rows = 5;
    if ( accIndex > 0 ) rows += 1;

    float height = 3.0 + keyheight * rows + 3.0;
    
    return height;

}


- ( float ) heightForLandscape : ( float ) width
{

    float sizetouse = width;

    float keywidth = sizetouse / 10.0;
    float keyheight = keywidth * 0.6;
    
    int rows = 5;
    if ( accIndex > 0 ) rows += 1;

    float height = 3.0 + keyheight * rows + 3.0;
    
    return height;
}


@end
