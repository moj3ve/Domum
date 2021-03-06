#import "DOMButton.h"
#import "DOMSettings.h"
#import <SpringBoard/SBAssistantController.h>
#import <SpringBoard/SBUIController.h>
#import <SpringBoard/SpringBoard+Private.h>
#import <UIKit/UIImage+Private.h>

@implementation DOMButton

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
        self.imageView.image = [UIImage imageNamed:@"Home" inBundle:[NSBundle bundleWithPath:@"/var/mobile/Library/Domum-Resources.bundle"]];
        self.imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self addSubview:self.imageView];

        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        panGesture.delegate = self;
        [self addGestureRecognizer:panGesture];

        UIPinchGestureRecognizer *scaleGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)];
        scaleGesture.delegate = self;
        [self addGestureRecognizer:scaleGesture];

        UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
        longPressGesture.delegate = self;
        longPressGesture.minimumPressDuration = 0.7;
        [self addGestureRecognizer:longPressGesture];

        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
        tapGesture.numberOfTapsRequired = 1;
        [self addGestureRecognizer:tapGesture];

        UITapGestureRecognizer *doubleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
        doubleTapGesture.numberOfTapsRequired = 2;
        doubleTapGesture.delegate = self;
        [self addGestureRecognizer:doubleTapGesture];

        [tapGesture requireGestureRecognizerToFail:doubleTapGesture];
        [tapGesture requireGestureRecognizerToFail:panGesture];
        [tapGesture requireGestureRecognizerToFail:scaleGesture];
        [tapGesture requireGestureRecognizerToFail:longPressGesture];

        _enableDrag = YES;
        self.userInteractionEnabled = YES;
    }

    return self;
}

- (void)handleTap:(UITapGestureRecognizer *)tap {
    SBUIController *controller = [%c(SBUIController) sharedInstance];
    if ([controller respondsToSelector:@selector(clickedMenuButton)]) {
        [controller clickedMenuButton];
    } else {
        [(SpringBoard *)[UIApplication sharedApplication] _simulateHomeButtonPress];
    }
}

- (void)handleDoubleTap:(UITapGestureRecognizer *)tap {
    SBUIController *controller = [%c(SBUIController) sharedInstance];
    if ([controller respondsToSelector:@selector(handleMenuDoubleTap)]) {
        [controller handleMenuDoubleTap];
    } else {
        [controller handleHomeButtonDoublePressDown];
    }
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)recognizer {
    SBAssistantController *assistantController = [%c(SBAssistantController) sharedInstance];
    [assistantController handleSiriButtonDownEventFromSource:1 activationEvent:1];
    [assistantController handleSiriButtonUpEventFromSource:1];
}

- (void)handlePan:(UIPanGestureRecognizer *)recognizer {
    if (!_enableDrag) {
        return;
    }

    switch (recognizer.state) {
      case UIGestureRecognizerStatePossible:
          break;
      case UIGestureRecognizerStateBegan:
          _initialPoint = recognizer.view.center;
          break;
      case UIGestureRecognizerStateChanged:
          break;
      case UIGestureRecognizerStateEnded:
      case UIGestureRecognizerStateCancelled:
      case UIGestureRecognizerStateFailed:
          [self snapButton];
          [[DOMSettings sharedSettings] saveButtonPosition:recognizer.view.center];
          return;
    }

    UIView *view = recognizer.view;
    CGPoint point = [recognizer translationInView:view.superview];

    CGPoint translatedPoint = CGPointMake(_initialPoint.x + point.x, _initialPoint.y + point.y);
    view.center = translatedPoint;
}

- (void)handlePinch:(UIPinchGestureRecognizer *)gesture {
    switch (gesture.state) {
        case UIGestureRecognizerStatePossible:
            break;
        case UIGestureRecognizerStateBegan: {
            _enableDrag = NO;
            break;
        }
        case UIGestureRecognizerStateChanged: {
            self.transform = CGAffineTransformScale(self.transform, gesture.scale, gesture.scale);
            gesture.scale = 1.0;
            break;
        }
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
            _enableDrag = YES;
            [self snapButton];
            break;
    }
}

- (void)snapButton {
    CGRect viewFrame = self.frame;
    CGRect superViewBounds = self.superview.bounds;

    if (viewFrame.origin.y < superViewBounds.origin.y) {
        viewFrame.origin.y = 0;
    } else if (CGRectGetMaxY(viewFrame) > superViewBounds.size.height) {
        viewFrame.origin.y = superViewBounds.size.height - viewFrame.size.height;
    }

    if (viewFrame.origin.x < superViewBounds.origin.x) {
        viewFrame.origin.x = 0;
    } else if (CGRectGetMaxX(viewFrame) > superViewBounds.size.width) {
        viewFrame.origin.x = superViewBounds.size.width - viewFrame.size.width;
    }

    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.frame = viewFrame;
    } completion:nil];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    if ([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]] && [otherGestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
        return NO;
    }

    return YES;
}

@end
