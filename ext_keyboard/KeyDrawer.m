#import "KeyDrawer.h"


void drawrect(
    CGContextRef context ,
    float x ,
    float y ,
    float w ,
    float h ,
    float r ,
    float g ,
    float b ,
    float a )
{

    CGContextSetFillColorWithColor( context,
        [ UIColor colorWithRed : r
                  green : g
                  blue : b
                  alpha : a ].CGColor );

    UIBezierPath *bezierPath = [ UIBezierPath
            bezierPathWithRoundedRect :
                CGRectMake(
                    x,
                    y,
                    w ,
                    h ) cornerRadius : 5.0 ];

    [bezierPath fill];
    
}


void drawlabel(
    CGContextRef context ,
    NSString* label ,
    NSMutableDictionary* textAttributes ,
    int fault ,
    float x ,
    float y ,
    float w ,
    float h )
{

    UIColor* textColor = [ UIColor darkGrayColor ];
    if ( fault ) textColor = [ UIColor lightGrayColor ];

    textAttributes[ NSForegroundColorAttributeName ] = textColor;

    NSAttributedString* string = [ [ NSAttributedString alloc ]
        initWithString : label
        attributes : textAttributes ];

    [ string drawInRect :
        CGRectMake( x ,
                    y ,
                    w ,
                    h ) ];

}


int calclinelength( NSString* string , int index )
{
    int subindex = 0;
    
    for ( subindex = index + 1 ;
          subindex < string.length ;
          subindex++ )
    {
        NSRange range = NSMakeRange( subindex , 1 );
        NSString* subletter = [ string substringWithRange : range  ];
        if ( [ subletter isEqualToString : @" " ] ) break;
    }
    
    return subindex;
}


CGPoint keysize_curr;       // current scaled size of keys


@implementation KeyDrawer
{

    UIFont* font;
    CGContextRef context;
    NSMutableDictionary* textAttributes;
    
    float xpos;
    float ypos;

    int row;
    int skips;

    CGPoint keyPos[ 100 ];

    CGPoint keysize_full;       // maximum size of keys

}


- ( id ) init
{

    self = [ super init ];
    
    font = [ UIFont
        fontWithName : @"Futura"
        size         : 20 ];
    
    NSMutableParagraphStyle* style = [ [ NSMutableParagraphStyle alloc ] init ];
    
    style.alignment = NSTextAlignmentCenter;

    textAttributes = [ [ NSMutableDictionary alloc ] initWithDictionary :
        @{ NSFontAttributeName : font,
        NSParagraphStyleAttributeName : style } ];

    return self;
    
}


- ( void ) resetWithContext : ( CGContextRef ) pContext
           strictness : ( float ) strictness
           accent : ( NSInteger ) accIndex
           view : ( UIView* ) view
{
    
    xpos = 0.0;
    ypos = 0.0;
    
    row = -1;
    skips = 0;
    context = pContext;

    keysize_full.x = view.frame.size.width / 10.0;
    keysize_full.y = ( view.frame.size.height - 6.0 ) / ( accIndex > 0 ? 6 : 5 );

    keysize_curr.x = keysize_full.x - 6.0;
    keysize_curr.y = keysize_full.y - 6.0;
    
    keysize_curr.x = keysize_curr.x - keysize_curr.x * 0.5 * strictness;
    keysize_curr.y = keysize_curr.y - keysize_curr.y * 0.5 * strictness;

}


- ( void ) gotoNextLineFromIndex : ( int ) index
           keyMap : ( NSString* ) keyMap
           view : ( UIView* ) view
{

    int subindex = calclinelength( keyMap , index );
    int count = subindex - index - 1;

    row += 1;
    skips = 0;

    float deadspace = view.frame.size.width - keysize_full.x * count;
    xpos = deadspace / 2.0 + keysize_full.x / 2.0;
    ypos = ( keysize_full.y - keysize_curr.y ) / 2.0 + keysize_full.y / 2.0 + keysize_full.y * row;

    keyPos[ index ] = CGPointMake( -keysize_curr.x , -keysize_curr.x );

}


- ( void ) drawPagingButtonForLetter : ( NSString* ) letter
           fault : ( BOOL ) isFault
           pageIndex : ( NSInteger ) pageIndex
           accIndex : ( NSInteger ) accIndex
           pageString : ( NSString* ) p2string
           accString : ( NSString*) acstring
{

    float color = 0.85;

    if ( [ letter isEqualToString : @"p" ] && pageIndex ) color = 0.55;
    else if ( [ letter isEqualToString : @"r" ] && accIndex ) color = 0.55;

    if ( [ letter isEqualToString : @"p" ] ) letter = [ p2string substringWithRange : NSMakeRange( 0 , 1 ) ];
    else if ( [ letter isEqualToString : @"r" ] ) letter = [ acstring substringWithRange : NSMakeRange( 0 , 1 ) ];

    drawrect( context ,
              xpos - keysize_curr.x / 2.0,
              ypos - keysize_curr.y / 2.0,
              keysize_curr.x ,
              keysize_curr.y * 2.0 ,
              color , color , color , 1.0 );

    drawlabel( context ,  letter , textAttributes , isFault ,
               xpos - keysize_curr.x / 2.0 ,
               ypos - font.lineHeight / 2.0 ,
               keysize_curr.x ,
               font.lineHeight );

}


- ( void ) drawNextEnterButtonForLetter : ( NSString* ) letter
           fault : ( BOOL ) isFault
{

    if ( skips == 0 )
    {
        skips = 2;

        drawrect( context ,
                  xpos - keysize_curr.x / 2.0,
                  ypos - keysize_curr.y / 2.0,
                  keysize_curr.x + keysize_full.x ,
                  keysize_curr.y ,
                  0.85 , 0.85 , 0.85 , 1.0 );

        if ( [ letter isEqualToString : @"n" ] )
        {
        
            float size = keysize_curr.x * 0.8;

            CGContextSetLineWidth( context , 1.5 );

            CGContextSetStrokeColorWithColor( context,
                [ UIColor colorWithRed : 0.95
                          green : 0.95
                          blue : 0.95
                          alpha : 1.0 ].CGColor );

            CGContextStrokeEllipseInRect(
                context ,
                CGRectMake( xpos + keysize_full.x / 2.0 - size / 2.0,
                            ypos - size / 2.0 ,
                            size ,
                            size ) );

            CGContextStrokeEllipseInRect(
                context ,
                CGRectMake( xpos + keysize_full.x / 2.0 - size / 4.0,
                            ypos - size / 2.0 ,
                            size / 2.0 ,
                            size ) );

            CGContextStrokeEllipseInRect(
                context ,
                CGRectMake( xpos + keysize_full.x / 2.0 - size / 2.0,
                            ypos - size / 4.0 ,
                            size ,
                            size / 2.0 ) );

            CGPoint linesa[ ] =
            {
                { xpos + keysize_full.x / 2.0 , ypos - size / 2.0 } ,
                { xpos + keysize_full.x / 2.0 , ypos + size / 2.0 } ,
            };

            CGContextAddLines( context , linesa , 2 );

            CGPoint linesb[ ] =
            {
                { xpos + keysize_full.x / 2.0 - size / 2.0 , ypos } ,
                { xpos + keysize_full.x / 2.0 + size / 2.0 , ypos } ,
            };

            CGContextMoveToPoint( context , linesb[2].x , linesb[2].y );
            CGContextAddLines( context , linesb , 2 );
            CGContextDrawPath( context , kCGPathStroke );

            letter = @"next";

        }
        else
        {
        
            letter = @"enter";
            
        }

        drawlabel( context ,  letter , textAttributes , isFault ,
                   xpos - keysize_curr.x / 2.0 ,
                   ypos - font.lineHeight / 2.0 ,
                   keysize_curr.x + keysize_full.x ,
                   font.lineHeight );

    }
    
}


- ( void ) drawShiftFault : ( BOOL ) isFault
           shift : ( BOOL ) shiftPressed
           caps : ( BOOL ) capsPressed
{

    NSString* letter = @"shift";

    float color = ( shiftPressed == 1 || capsPressed == 1 ) ? 0.55 : 0.85;

    drawrect( context ,
              xpos - keysize_curr.x - ( keysize_full.x - keysize_curr.x ) / 2.0,
              ypos - keysize_curr.y / 2.0,
              keysize_curr.x + keysize_full.x / 2.0 ,
              keysize_curr.y ,
              color , color , color , 1.0 );

    drawlabel( context ,  letter , textAttributes , isFault ,
               xpos - keysize_curr.x - ( keysize_full.x - keysize_curr.x ) / 2.0 ,
               ypos - font.lineHeight / 2.0 ,
               keysize_curr.x + keysize_full.x / 2.0 ,
               font.lineHeight );

}


- ( void ) drawDelFault : ( BOOL ) isFault
{

    NSString* letter = @"del";

    drawrect( context ,
              xpos - keysize_curr.x / 2.0,
              ypos - keysize_curr.y / 2.0,
              keysize_curr.x + keysize_full.x / 2.0 ,
              keysize_curr.y ,
              0.85 , 0.85 , 0.85 , 1.0 );

    drawlabel( context ,  letter , textAttributes , isFault ,
               xpos - keysize_curr.x / 2.0 ,
               ypos - font.lineHeight / 2.0 ,
               keysize_curr.x + keysize_full.x / 2.0 ,
               font.lineHeight );


}


- ( void ) drawSpace
{

    if ( skips == 0 )
    {
        skips = 6;

        drawrect( context ,
                  xpos - keysize_curr.x / 2.0 ,
                  ypos - keysize_curr.y / 2.0,
                  ( keysize_full.x / 2.0 ) * 12 - ( keysize_full.x - keysize_curr.x ) ,
                  keysize_curr.y ,
                  0.85 , 0.85 , 0.85 , 1.0 );
    }

}


- ( void ) drawGlyph : ( NSString* ) letter
           fault : ( BOOL ) isFault
           actualGlyph : ( NSString* ) actualGlyph
           touchPos : ( CGPoint ) touch_pos
{

    float color = 0.95;

    if ( isFault )
    {
        if ( fabs(xpos - touch_pos.x) > keysize_full.x / 1.5 ||
             fabs(ypos - touch_pos.y) > keysize_full.y / 1.5 )
        {
            color = 0.45;
        }
    }
    
    if ( [ actualGlyph isEqualToString : letter ] )
    {
        color = 0.60;
    }

    drawrect( context ,
              xpos - keysize_curr.x / 2.0 ,
              ypos - keysize_curr.y / 2.0,
              keysize_curr.x ,
              keysize_curr.y ,
              color , color , color , 1.0 );

    drawlabel( context ,  letter , textAttributes , isFault ,
               xpos - keysize_curr.x / 2.0 ,
               ypos - font.lineHeight / 2.0 ,
               keysize_curr.x ,
               font.lineHeight  );

}


- ( void ) drawTipFault : ( BOOL ) isFault
           tapPos : ( CGPoint ) tap_pos
           height : ( float ) height
{

    // draw tip point

    float colora = 1.0;
    float colorb = 1.0;
    float colorc = 1.0;

    if ( isFault )
    {
        colora = 1.0;
        colorb = 0.0;
        colorc = 0.0;
    }

    drawrect( context ,
              tap_pos.x - 5.0 ,
              ( height - tap_pos.y ) - 5.0 ,
              10.0 ,
              10.0 ,
              colora , colorb , colorc , 0.8 );

}


- ( void ) storeKeyAtIndex : ( int ) index
{
    
    if ( skips > 0 ) skips--;

    keyPos[ index ] = CGPointMake( xpos , ypos );

    xpos += keysize_full.x;

}


- ( struct keysearchinfo ) keyIndexForPosition : ( CGPoint ) touchPos
                           keyMap : ( NSString* ) keymap
{

    struct keysearchinfo result = { -1 , 0.0 , 0.0 };

    result.minx = [ [ UIScreen mainScreen ] bounds ].size.width;
    result.miny = keysize_full.y / 2.0;
    
    for ( int index = 0 ;
              index < keymap.length ;
              index++ )
    {
        CGPoint value = keyPos[ index ];
        
        float dx = touchPos.x - value.x;
        float dy = touchPos.y - value.y;
        
        if ( fabs( dx ) < result.minx &&
             fabs( dy ) < keysize_full.y / 2.0 )
        {
            result.pick = index;
            result.minx = dx;
            result.miny = dy;
        }
    }

    return result;

}


+ ( CGPoint ) getKeySize
{
    
    return keysize_curr;
    
}


@end
