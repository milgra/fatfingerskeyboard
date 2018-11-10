#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface KeyDrawer : NSObject

- ( void ) resetWithContext : ( CGContextRef ) context
           strictness : ( float ) strictness
           accent : ( NSInteger ) accIndex
           view : ( UIView* ) view;

- ( void ) gotoNextLineFromIndex : ( int ) index
           keyMap : ( NSString* ) keyMap
           view : ( UIView* ) view;

- ( void ) drawPagingButtonForLetter : ( NSString* ) letter
           fault : ( BOOL ) isFault
           pageIndex : ( NSInteger ) pageIndex
           accIndex : ( NSInteger ) accIndex
           pageString : ( NSString* ) p2string
           accString : ( NSString*) acstring;

- ( void ) drawNextEnterButtonForLetter : ( NSString* ) letter
           fault : ( BOOL ) isFault;

- ( void ) drawShiftFault : ( BOOL ) isFault
           shift : ( BOOL ) shiftPressed
           caps : ( BOOL ) capsPressed;

- ( void ) drawDelFault : ( BOOL ) isFault;

- ( void ) drawSpace;

- ( void ) drawGlyph : ( NSString* ) letter
           fault : ( BOOL ) isFault
           actualGlyph : ( NSString* ) actualGlyph
           touchPos : ( CGPoint ) touch_pos;

- ( void ) drawTipFault : ( BOOL ) isFault
           tapPos : ( CGPoint ) tap_pos
           height : ( float ) height;

- ( void ) storeKeyAtIndex : ( int ) index;

struct keysearchinfo
{
    int pick;
    float minx;
    float miny;
};

- ( struct keysearchinfo ) keyIndexForPosition : ( CGPoint ) touchPos
    keyMap : ( NSString* ) keymap;

+ ( CGPoint ) getKeySize;

@end

NS_ASSUME_NONNULL_END
