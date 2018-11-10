#import <UIKit/UIKit.h>
#import <StoreKit/StoreKit.h>

@interface ViewController : UIViewController < UITextViewDelegate ,
                                               SKPaymentTransactionObserver ,
                                               SKProductsRequestDelegate >

@end

