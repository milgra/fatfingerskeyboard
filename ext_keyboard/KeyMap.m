#import "KeyMap.h"

@implementation KeyMap


+ ( void ) generateAccentRibbon : ( NSMutableString* ) keymap
           string : ( NSString* ) acstring
           state : ( NSInteger ) accIndex
{

    [ keymap appendString : @" " ]; // newline
    
    NSUInteger start = 0;
    NSUInteger length = acstring.length;
    
    if ( accIndex == 1 && length > 10 )
    {
        length = 10;
    }
    
    if ( accIndex == 2 && length > 10 )
    {
        start = 10;
        length -= 10;
    }
    
    NSRange range = NSMakeRange( start , length );
    [ keymap appendString : [ acstring substringWithRange : range ] ];

}


+ ( void ) generateAlternatePage : ( NSMutableString* ) keymap string : ( NSString* ) p2string
{
    
    for ( int index = 0 ;
              index < 4 ;
              index++ )
    {
        [ keymap appendString : @" " ]; // newline
        
        if ( p2string.length > index * 10 )
        {
            NSRange range = NSMakeRange( index * 10 , 10 );
            [ keymap appendString : [ p2string substringWithRange : range ] ];
        }
    }
    
}


+ ( void ) generateMainPage : ( NSMutableString* ) keymap string : ( NSString* ) p1string
{

    NSRange range_a = NSMakeRange( 0 , 10 );
    NSRange range_b = NSMakeRange( 10 , 9 );
    NSRange range_c = NSMakeRange( 19 , 7 );

    // first row
    [ keymap appendString : @" " ];
    [ keymap appendString : [ p1string substringWithRange : range_a ] ];
    
    // second row
    [ keymap appendString : @" " ];
    [ keymap appendString : [ p1string substringWithRange : range_b ] ];

    // third row
    [ keymap appendString : @" " ];
    [ keymap appendString : @"h" ]; // shift
    [ keymap appendString : [ p1string substringWithRange : range_c ] ];
    [ keymap appendString : @"b" ]; // backspace
    
    // fourth row
    [ keymap appendString : @" " ]; // newline
    [ keymap appendString : @"nnssssssee" ]; // next space enter
    
}


+ ( void ) generateLastLine : ( NSMutableString* ) keymap string : ( NSString* ) p1string
{

    NSRange range = NSMakeRange( 26 , 8 );

    [ keymap appendString : @" " ]; // newline
    [ keymap appendString : @"p" ]; // page switch
    [ keymap appendString : [ p1string substringWithRange : range ] ];
    [ keymap appendString : @"r" ]; // accent ribbon switch

}


+ ( NSMutableString* )
    generateKeymapWithPage : ( NSInteger )
    pageIndex accent : ( NSInteger ) accIndex
{
    // parsing keymap in a format parsable by the keyboard drawer :
    // @" ÁÉÍÓÖŐÚÜŰ"
    // @" QWERTYUIOP ASDFGHJKL hZXCVBNMb"
    // @" 1234567890 <>/\\()[]{} +-*=&$&@#^ _|~¢£¥•___"
    // @" nnssssssee"
    // @" p.,;?!:'\"r"

    NSUserDefaults* defaults = [ [ NSUserDefaults alloc ] initWithSuiteName : @"group.milgra.keyboard" ];

    NSString* p1string = [ defaults objectForKey : @"p1string" ];
    NSString* p2string = [ defaults objectForKey : @"p2string" ];
    NSString* acstring = [ defaults objectForKey : @"acstring" ];

    NSMutableString* keymap = [ NSMutableString string ];
    
    if ( accIndex > 0  )
    {
        [ KeyMap generateAccentRibbon : keymap
                 string : acstring
                 state : accIndex ];
    }
    if ( pageIndex == 1 )
    {
        [ KeyMap generateAlternatePage : keymap
                 string : p2string ];
    }
    else
    {
        [ KeyMap generateMainPage : keymap
                 string : p1string ];
    }
    
    [ KeyMap generateLastLine : keymap
             string : p1string ];
    
    return keymap;
    
}


@end
