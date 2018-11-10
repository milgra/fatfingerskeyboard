#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface KeyMap : NSObject

+ ( NSMutableString* ) generateKeymapWithPage : ( NSInteger ) pageIndex
                       accent : ( NSInteger ) accIndex;

@end

NS_ASSUME_NONNULL_END
