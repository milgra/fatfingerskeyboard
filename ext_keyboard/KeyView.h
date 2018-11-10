#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface KeyView : UIView

- ( float ) calculateHeightForPortraitWidth : ( float ) width;
- ( float ) calculateHeightForLandscapeWidth : ( float ) width;

@end

NS_ASSUME_NONNULL_END
