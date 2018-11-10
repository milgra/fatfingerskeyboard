#import "ViewController.h"

@interface ViewController () 
{

    NSUserDefaults* defaults;
    UITapGestureRecognizer*  tapper;
    
    SKProductsRequest* request;
    NSArray* products;
    
    SKProduct* productA;
    SKProduct* productB;
    SKProduct* productC;
    
}

@property (weak, nonatomic) IBOutlet UIView *setup_view;
@property (weak, nonatomic) IBOutlet UIView *donate_view;

@property (weak, nonatomic) IBOutlet UIButton *reset_btn;
@property (weak, nonatomic) IBOutlet UIButton *donate_a_btn;
@property (weak, nonatomic) IBOutlet UIButton *donate_b_btn;
@property (weak, nonatomic) IBOutlet UIButton *donate_c_btn;
@property (weak, nonatomic) IBOutlet UIButton *settings_btn;
@property (weak, nonatomic) IBOutlet UIButton *homepage_btn;

@property (weak, nonatomic) IBOutlet UISlider *timeout_sld;
@property (weak, nonatomic) IBOutlet UISlider *strictness_sld;

@property (weak, nonatomic) IBOutlet UITextView *page_a_tview;
@property (weak, nonatomic) IBOutlet UITextView *page_b_tview;
@property (weak, nonatomic) IBOutlet UITextView *page_c_tview;

@property (weak, nonatomic) IBOutlet UIStackView *stack_view;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@end


@implementation ViewController


- ( id ) initWithCoder : ( NSCoder* ) aDecoder
{

    self = [ super initWithCoder : aDecoder ];
    
    defaults = [ [ NSUserDefaults alloc ]
        initWithSuiteName : @"group.milgra.keyboard" ];
    
    // get version and build for settings bundle
    
    NSString *version = [ [ [ NSBundle mainBundle ] infoDictionary ]
            objectForKey : @"CFBundleShortVersionString" ];
    
    NSString *build = [ [ [ NSBundle mainBundle ] infoDictionary ]
            objectForKey : ( NSString* ) kCFBundleVersionKey ];

    [ [ NSUserDefaults standardUserDefaults ]
        setObject : version
        forKey : @"version_pref" ];
    
    [ [ NSUserDefaults standardUserDefaults ]
        setObject : build
        forKey : @"build_pref" ];
    
    // setup transaction observer
    
    [ [ SKPaymentQueue defaultQueue ] addTransactionObserver : self ];

    return self;
    
}


- ( void ) viewDidLoad
{

    [ super viewDidLoad ];
    
    // post-storyboard setup
    
    _reset_btn.layer.cornerRadius = 10;
    _reset_btn.clipsToBounds = YES;
    
    _donate_a_btn.layer.cornerRadius = 10;
    _donate_a_btn.clipsToBounds = YES;
    _donate_a_btn.enabled = NO;
    _donate_b_btn.layer.cornerRadius = 10;
    _donate_b_btn.clipsToBounds = YES;
    _donate_b_btn.enabled = NO;
    _donate_c_btn.layer.cornerRadius = 10;
    _donate_c_btn.clipsToBounds = YES;
    _donate_c_btn.enabled = NO;

    _settings_btn.layer.cornerRadius = 10;
    _settings_btn.clipsToBounds = YES;
    
    _homepage_btn.layer.cornerRadius = 10;
    _homepage_btn.clipsToBounds = YES;
    
    _page_a_tview.layer.cornerRadius = 10;
    _page_b_tview.layer.cornerRadius = 10;
    _page_c_tview.layer.cornerRadius = 10;
    
    // tap detection for tap outside mapping textfields

    tapper = [ [ UITapGestureRecognizer alloc ]
                initWithTarget : self
                action : @selector(handleSingleTap:)];
    
    tapper.cancelsTouchesInView = NO;
    
    [ self.view addGestureRecognizer : tapper ];
    
    // load initial values

    NSInteger version = [ defaults integerForKey : @"version" ];
    
    if ( version == 0 )
    {
        // first run, fill shared object with initial values

        [ defaults setFloat : 1.0 forKey : @"version" ];
        [ defaults setFloat : 0.0 forKey : @"strictness" ];
        [ defaults setFloat : 0.5 forKey : @"timeout" ];

        _strictness_sld.value = [ defaults floatForKey : @"strictness" ];
        _timeout_sld.value = [ defaults floatForKey : @"timeout" ];

        [ self resetFields ];
    }
    else
    {
        _page_a_tview.text = [ defaults objectForKey : @"p1string" ];
        _page_b_tview.text = [ defaults objectForKey : @"p2string" ];
        _page_c_tview.text = [ defaults objectForKey : @"acstring" ];
        
        _strictness_sld.value = [ defaults floatForKey : @"strictness" ];
        _timeout_sld.value = [ defaults floatForKey : @"timeout" ];

        [ self formatFields ];
    }
    
    // check if FatFingers keyboard is already installed, remove help stack
    
    NSArray *array = [ [ NSUserDefaults standardUserDefaults ]
        objectForKey : @"AppleKeyboards" ];
    
    if ( [ array indexOfObject : @"com.milgra.app-keyboard.ext-keyboard" ] != NSNotFound )
    {
        [ _setup_view removeFromSuperview ];
    }
    
    _donate_view.hidden = YES;
    
    // load donation products from store
    
    [ self validateProductIdentifiers ];
    
}


- ( void ) viewDidAppear : ( BOOL ) animated
{

    [ super viewDidAppear : animated ];
    
    NSNotificationCenter *nc = [ NSNotificationCenter defaultCenter ];
    
    [ nc addObserver : self
         selector : @selector(keyboardWillShow:)
         name : UIKeyboardWillShowNotification
         object : nil];
    
    [ nc addObserver : self
         selector : @selector(keyboardWillHide:)
         name : UIKeyboardWillHideNotification
         object : nil];
    
}


- ( void ) viewDidDisappear : ( BOOL ) animated
{

    [ super viewDidDisappear : animated ];
    
    NSNotificationCenter *nc = [ NSNotificationCenter defaultCenter ];
    
    [ nc removeObserver : self
         name : UIKeyboardWillShowNotification
         object : nil ];
    [ nc removeObserver : self
         name : UIKeyboardWillHideNotification
         object : nil ];
    
}


- ( void ) keyboardWillShow : ( NSNotification* ) aNotification
{

    NSDictionary* info = [ aNotification userInfo ];
    CGRect keyboardSize = [ [ info objectForKey : UIKeyboardFrameEndUserInfoKey ] CGRectValue ];

    UIView* source = nil;
    
    if ( _page_a_tview.isFirstResponder ) source = _page_a_tview;
    if ( _page_b_tview.isFirstResponder ) source = _page_b_tview;
    if ( _page_c_tview.isFirstResponder ) source = _page_c_tview;

    CGRect global = [ self.view
        convertRect : source.frame
        fromView    : source ];

    float fieldBottom = global.origin.y + global.size.height;
    float keyboardTop = [ [ UIScreen mainScreen ] bounds].size.height - keyboardSize.size.height;
    float offset = 0.0;

    if ( fieldBottom > keyboardTop ) offset = fieldBottom - keyboardTop;

    UIEdgeInsets contentInsets = UIEdgeInsetsMake( 0.0 , 0.0 , keyboardSize.size.height , 0.0 );
    NSTimeInterval duration = [ [ info objectForKey : UIKeyboardAnimationDurationUserInfoKey ] doubleValue ];
    
    // move textfield up to visibility
    
    [ UIView animateWithDuration : duration
             delay      : 0
             options    : UIViewAnimationOptionBeginFromCurrentState
             animations :
             ^{
             
                self.scrollView.contentInset = contentInsets;
                self.scrollView.scrollIndicatorInsets = contentInsets;
                
                CGPoint oldoffset = self.scrollView.contentOffset;
                oldoffset.y += offset;
                
                self.scrollView.contentOffset = oldoffset;
                [self.scrollView setNeedsDisplay];
                
             }
             completion : nil ];
    
}


- ( void ) keyboardWillHide : ( NSNotification* ) aNotification
{

    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    NSDictionary* info = [ aNotification userInfo ];
    NSTimeInterval duration = [ [ info objectForKey : UIKeyboardAnimationDurationUserInfoKey ] doubleValue ];
    
    // scroll back
    
    [ UIView animateWithDuration : duration
             delay      : 0
             options    : UIViewAnimationOptionBeginFromCurrentState
             animations :
             ^{
             
                self.scrollView.contentInset = contentInsets;
                self.scrollView.scrollIndicatorInsets = contentInsets;
                
             }
             completion : nil ];
    
}


- ( BOOL ) textView : ( UITextView* ) textView
           shouldChangeTextInRange : ( NSRange )range
           replacementText : ( NSString* ) text
{

    if ( [ text isEqualToString : @"\n" ] )
    {
        [ _page_a_tview endEditing : YES ];
        [ _page_b_tview endEditing : YES ];
        [ _page_c_tview endEditing : YES ];
        
        [ textView resignFirstResponder ];

        [ self formatFields ];

        return NO;
    }

    return YES;
    
}


- ( void ) handleSingleTap : ( UITapGestureRecognizer* ) sender
{

    [ _page_a_tview endEditing : YES ];
    [ _page_b_tview endEditing : YES ];
    [ _page_c_tview endEditing : YES ];
    
    [ self formatFields ];
    
}


- ( IBAction ) openKeyboardSettingsPressed : ( id ) sender
{

    [ [ UIApplication sharedApplication ]
        openURL : [ NSURL URLWithString : UIApplicationOpenSettingsURLString ]
        options : @{}
        completionHandler : nil ];
    
}


- ( IBAction ) openHomepagePressed : ( id ) sender
{

    NSDictionary *options = @{UIApplicationOpenURLOptionUniversalLinksOnly : @NO};
    NSURL *URL = [ NSURL URLWithString : @"http://milgra.com" ];
    [ [ UIApplication sharedApplication ]
        openURL : URL
        options : options
        completionHandler : NULL ];
    
}


- ( IBAction ) donate_a_pressed : ( id ) sender
{

    if ( productA != nil )
    {
        SKMutablePayment *payment = [ SKMutablePayment paymentWithProduct : productA ];
        [ [ SKPaymentQueue defaultQueue ] addPayment : payment ];
    }
    
}


- ( IBAction ) donate_b_pressed : ( id ) sender
{

    if ( productB != nil )
    {
        SKMutablePayment *payment = [ SKMutablePayment paymentWithProduct : productB ];
        [ [ SKPaymentQueue defaultQueue ] addPayment : payment ];
    }
    
}


- ( IBAction ) donate_c_pressed : ( id ) sender
{

    if ( productC != nil )
    {
        SKMutablePayment *payment = [ SKMutablePayment paymentWithProduct : productC ];
        [ [ SKPaymentQueue defaultQueue ] addPayment : payment ];
    }
    
}


- ( IBAction) reset_pressed : ( id ) sender
{

    [self resetFields];
    [self formatFields];
    
}


- ( IBAction ) strictness_changed : ( id ) sender
{

    [ defaults setFloat : _strictness_sld.value  forKey : @"strictness" ];
    [ defaults synchronize ];
    
}


- ( IBAction ) timeout_changed : ( id ) sender
{

    [ defaults setFloat : _timeout_sld.value  forKey : @"timeout" ];
    [ defaults synchronize ];
    
}


- ( void ) resetFields
{

    _page_a_tview.text = @"QWERTYUIOPASDFGHJKLZXCVBNM.,;?!:'\"";
    _page_b_tview.text = @"1234567890<>/\\()[]{}+-*=&$&@#^_|~¢£¥•§©™";
    _page_c_tview.text = @"ÁÉÍÓÖŐÚÜŰ";
    
    [ self formatFields ];
    
}


- ( void ) formatFields
{

    // break down to 10 - 9 - 7 - 8

    NSString* stripped = [ _page_a_tview.text
        stringByReplacingOccurrencesOfString : @" "
        withString : @"" ];
    
    NSMutableString* result = [ NSMutableString string ];
    
    for ( int index = 0 ;
              index < 34 ;
              index++ )
    {
        if ( index < stripped.length )
        {
            NSString* glyph = [ stripped substringWithRange : NSMakeRange( index , 1 ) ];
            [ result appendString : [ glyph uppercaseString ] ];
        }
        else
        {
            [ result appendString: @"•" ];
        }
        if ( index == 9 || index == 18 || index == 25 ) [ result appendString : @" " ];
    }

    _page_a_tview.text = result;

    // break down to 10 - 10 - 10 - 10

    stripped = [ _page_b_tview.text
        stringByReplacingOccurrencesOfString : @" "
        withString : @"" ];
    
    result = [ NSMutableString string ];
    
    for ( int index = 0 ;
              index < 40 ;
              index++ )
    {
        if ( index > 0 && index % 10 == 0 ) [ result appendString : @" " ];
        if ( index < stripped.length )
        {
            NSString* glyph = [ stripped substringWithRange : NSMakeRange( index , 1 ) ];
            [ result appendString : [ glyph uppercaseString ] ];
        }
        else
        {
            [ result appendString: @"•" ];
        }
    }

    _page_b_tview.text = result;

    // break down to 10

    stripped = [ _page_c_tview.text
        stringByReplacingOccurrencesOfString : @" "
        withString : @"" ];
    
    result = [ NSMutableString string ];
    
    for ( int index = 0 ;
              index < 20 ;
              index++ )
    {
        if ( index < stripped.length )
        {
            NSString* glyph = [ stripped substringWithRange : NSMakeRange( index , 1 ) ];
            [ result appendString : [ glyph uppercaseString ] ];
            if ( index == 9 ) [ result appendString : @" " ];
        }
        else
        {
            if ( index == 0 ) [ result appendString: @"•" ];
        }
    }

    _page_c_tview.text = result;

    [ defaults setObject : [_page_a_tview.text stringByReplacingOccurrencesOfString: @" " withString : @"" ] forKey : @"p1string" ];
    [ defaults setObject : [_page_b_tview.text stringByReplacingOccurrencesOfString: @" " withString : @"" ] forKey : @"p2string" ];
    [ defaults setObject : [_page_c_tview.text stringByReplacingOccurrencesOfString: @" " withString : @"" ] forKey : @"acstring" ];
    [ defaults synchronize ];

}


- ( void ) validateProductIdentifiers
{

    NSArray* productIds = @[ @"donationmedium" , @"donationsmall" , @"donationnormal" ];

    request = [ [ SKProductsRequest alloc ] initWithProductIdentifiers : [ NSSet setWithArray : productIds ] ];
    request.delegate = self;
    [ request start ];
    
}


- ( void ) productsRequest : ( SKProductsRequest* ) request
           didReceiveResponse : ( SKProductsResponse* ) response
{

    products = response.products;
    
    for ( SKProduct* product in response.products )
    {
    
        NSNumberFormatter *numberFormatter = [ [ NSNumberFormatter alloc ] init ];
        [ numberFormatter setFormatterBehavior : NSNumberFormatterBehavior10_4 ];
        [ numberFormatter setNumberStyle : NSNumberFormatterCurrencyStyle ];
        [ numberFormatter setLocale : product.priceLocale ];
        NSString *formattedPrice = [ numberFormatter stringFromNumber : product.price ];

        if ( [ product.productIdentifier isEqualToString : @"donationsmall" ] )
        {
            productA = product;
            dispatch_async( dispatch_get_main_queue() , ^{
                [ self->_donate_a_btn setTitle : formattedPrice forState : UIControlStateNormal ];
                [ self->_donate_a_btn setTitle : formattedPrice forState : UIControlStateHighlighted ];
                [ self->_donate_a_btn setEnabled : YES ];
            });
        }
        if ( [ product.productIdentifier isEqualToString : @"donationmedium" ] )
        {
            productB = product;
            dispatch_async( dispatch_get_main_queue() , ^{
                [ self->_donate_b_btn setTitle : formattedPrice forState : UIControlStateNormal ];
                [ self->_donate_b_btn setTitle : formattedPrice forState : UIControlStateHighlighted ];
                [ self->_donate_b_btn setEnabled : YES ];
            });
        }
        if ( [ product.productIdentifier isEqualToString : @"donationnormal" ] )
        {
            productC = product;
            dispatch_async( dispatch_get_main_queue() , ^{
                [ self->_donate_c_btn setTitle : formattedPrice forState : UIControlStateNormal ];
                [ self->_donate_c_btn setTitle : formattedPrice forState : UIControlStateHighlighted ];
                [ self->_donate_c_btn setEnabled : YES ];
            });
        }

        dispatch_async( dispatch_get_main_queue() , ^{
            self->_donate_view.hidden = NO;
        });

    }
 
    for ( NSString *invalidIdentifier in response.invalidProductIdentifiers )
    {
        NSLog( @"invalid product : %@" , invalidIdentifier );
    }

}


- ( void ) paymentQueue : ( SKPaymentQueue* ) queue
           updatedTransactions : ( NSArray* ) transactions
{

    NSString* result = @"";

    for ( SKPaymentTransaction* transaction in transactions )
    {
        switch ( transaction.transactionState )
        {
            // Call the appropriate custom method for the transaction state.
            case SKPaymentTransactionStatePurchasing :
                result = @"Purchasing";
                break;
                
            case SKPaymentTransactionStateDeferred :
                result = @"Deferred";
                [ [ SKPaymentQueue defaultQueue ] finishTransaction : transaction ];
                break;
                
            case SKPaymentTransactionStateFailed :
                result = @"Failed";
                [ [ SKPaymentQueue defaultQueue ] finishTransaction : transaction ];
                break;
                
            case SKPaymentTransactionStatePurchased :
            {
                result = @"Thank you for your donation!";
                UIAlertController* alert =
                    [ UIAlertController
                        alertControllerWithTitle : @"Thank you"
                        message : result
                        preferredStyle : UIAlertControllerStyleAlert ];
                
                UIAlertAction* defaultAction = [ UIAlertAction
                    actionWithTitle : @"OK"
                    style : UIAlertActionStyleDefault
                    handler : ^(UIAlertAction * action ) { } ];
                
                [ alert addAction : defaultAction ];
                
                [ self presentViewController : alert
                       animated : YES
                       completion : nil ];

                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                break;
            }
            
            case SKPaymentTransactionStateRestored :
                result = @"Restored";
                [ [ SKPaymentQueue defaultQueue ] finishTransaction : transaction ];
                break;
                
            default:
                [ [ SKPaymentQueue defaultQueue ] finishTransaction : transaction ];
                NSLog( @"Unexpected transaction state %@" , @(transaction.transactionState) );
                break;
        }

        NSLog( @"updateTransaction %@ %@" , transaction.error , result );

    }
    
}

@end

