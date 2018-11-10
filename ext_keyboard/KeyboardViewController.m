#import "KeyboardViewController.h"
#import "KeyView.h"

@interface KeyboardViewController ( )
{

    KeyView* keyView;
    NSNotificationCenter *center;
    NSLayoutConstraint* heightConstraint;
    
}
@end


@implementation KeyboardViewController


- ( void ) resize
{
    
    float height = [ keyView calculateHeightForPortraitWidth : self.view.frame.size.width ];    
    if ( [ UIScreen mainScreen ].bounds.size.width > [ UIScreen mainScreen ].bounds.size.height )
    {
        height = [ keyView calculateHeightForLandscapeWidth : self.view.frame.size.width ];
    }
    
    if ( heightConstraint.constant != height ) [ heightConstraint setConstant : height ];
    
}


- ( void ) viewDidLayoutSubviews
{

    [ self resize ];
    
    CGRect frame = self.view.frame;
    frame.size.height = heightConstraint.constant;
    
    [ keyView setFrame : frame ];
    [ keyView setNeedsDisplay ];
    
}


- ( void ) viewDidLoad
{

    [ super viewDidLoad ];
    
    heightConstraint = [ NSLayoutConstraint
            constraintWithItem  : self.view
            attribute           : NSLayoutAttributeHeight
            relatedBy           : NSLayoutRelationEqual
            toItem              : nil
            attribute           : NSLayoutAttributeNotAnAttribute
            multiplier          : 0.0
            constant            : 200.0 ];

    [ heightConstraint setPriority : UILayoutPriorityRequired - 1 ];

    [self.view addConstraint : heightConstraint];

    keyView = [ [ KeyView alloc ] init ];

    [ self.view addSubview : keyView ];

    [ keyView setBackgroundColor : [ UIColor whiteColor ] ];
    [ keyView setTranslatesAutoresizingMaskIntoConstraints : NO ];
    
    [ keyView.leftAnchor    constraintEqualToAnchor : self.view.leftAnchor ].active = YES;
    [ keyView.rightAnchor   constraintEqualToAnchor : self.view.rightAnchor ].active = YES;
    [ keyView.topAnchor     constraintEqualToAnchor : self.view.topAnchor ].active = YES;
    [ keyView.bottomAnchor  constraintEqualToAnchor : self.view.bottomAnchor ].active = YES;
    
    center = [ NSNotificationCenter defaultCenter ];
    
    [ center addObserver : self
             selector : @selector(onMessage:)
             name : @"control"
             object : nil ];

}


- ( void ) onMessage : ( NSNotification* ) aNotification
{
    NSDictionary* dict = aNotification.object;
    NSString* name = dict[ @"name" ];
    
    if ( [ name isEqualToString : @"resize" ] )
    {
        [ self resize ];
    }
    else if ( [ name isEqualToString : @"next" ] )
    {
        [ self advanceToNextInputMode ];
    }
    else if ( [ name isEqualToString : @"insert" ] )
    {
        NSString* letter = dict[ @"letter" ];
        [ self.textDocumentProxy insertText : letter ];
    }
    else if ( [ name isEqualToString : @"delete" ] )
    {
        [ self.textDocumentProxy deleteBackward ];
    }
    else if ( [ name isEqualToString : @"adjust" ] )
    {
        NSNumber* number = dict[ @"value" ];
        [ self.textDocumentProxy adjustTextPositionByCharacterOffset : number.integerValue ];
    }
}


- ( void ) textWillChange : ( id < UITextInput > ) textInput
{
    // The app is about to change the document's contents. Perform any preparation here.
}


- ( void ) textDidChange : ( id < UITextInput > ) textInput
{
    // The app has just changed the document's contents, the document context has been updated.
}


@end
