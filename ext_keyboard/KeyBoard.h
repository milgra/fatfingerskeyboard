#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface KeyBoard : NSObject

- ( id ) initWithView : ( UIView* ) pView;
- ( void ) draw;

- ( BOOL ) touchStarted : ( CGPoint ) position;
- ( void ) touchEnded;
- ( void ) stopDelete;

- ( float ) heightForPortrait : ( float ) width;
- ( float ) heightForLandscape : ( float ) width;

@end

NS_ASSUME_NONNULL_END
