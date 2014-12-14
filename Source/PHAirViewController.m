//
//  PHAirViewController.m
//  PHAirTransaction
//
//  Created by Ta Phuoc Hai on 1/7/14.
//  Copyright (c) 2014 Phuoc Hai. All rights reserved.
//

/*
 view structer
 
 -----------------
 view
   ---------------
   wrapperView
     ---------------
     contentView
       -------------
       leftView
         -----------
         sessionView
           ---------
           title
           ---------
           button
       -------------
       rightView
         ---------
         airImageView
 */

#import "PHAirViewController.h"
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>
#import "UIViewAdditions.h"
#import "PPImageTitleButton.h"
#import "PHAirViewAppearanceLayout.h"

#define kMenuItemHeight 80
#define kSessionWidth   220

#define kLeftViewTransX      -50
#define kLeftViewRotate      -5
#define kAirImageViewRotate  -25
#define kRightViewTransX     180
#define kRightViewTransZ     -150

#define kAirImageViewRotateMax -42

#define kDuration 0.2f
#define kInteractiveRightViewSnapBackInPercent 0.6f

#define kIndexPathOutMenu [NSIndexPath indexPathForRow:999 inSection:0]

CGFloat AirDegreesToRadians(CGFloat degrees) {return degrees * M_PI / 180;};
CGFloat AirRadiansToDegrees(CGFloat radians) {return radians * 180/M_PI;};

static NSString * const PHSegueRootIdentifier  = @"phair_root";

@interface PHAirViewController()

@property (nonatomic, strong) UIView      * wrapperView;
@property (nonatomic, strong) UIView      * contentView; // ContentView contains both leftView and rightView
@property (nonatomic, strong) UIView      * leftView;   // LeftView Contains SessionView
@property (nonatomic, strong) UIView      * rightView;  // RightView Contains self.airImageView
@property (nonatomic, strong) UIImageView * airImageView;
@property (nonatomic, strong) UIScrollView *leftViewWrapper;

@property (nonatomic)         float         lastDeegreesRotateTransform;

// pan for scroll
@property (nonatomic, strong) UIPanGestureRecognizer * scrollLeftViewPanGestureRecognizer;
@property (nonatomic, strong) UIPanGestureRecognizer * interactAirViewPanGestureRecognizer;
@property (nonatomic, strong) UITapGestureRecognizer * airViewTapGestureRecognizer;

@property (nonatomic, strong) PHAirViewAppearanceLayout *appearanceLayout;

// showAirView indicate whether to show PHAirViewController or show frontViewController;
@property (nonatomic, assign) BOOL showAirView;
@property (nonatomic, assign) CGFloat previousRightViewOpenInteractionInPercent;
@end

@implementation PHAirViewController {
    
    // number of data
    NSInteger  session;
    NSArray  * rowsOfSession;
    
    // sesion view
    NSMutableDictionary    * sessionViews;    
    
    // current index sesion view
    int        currentIndexSession;    
    
    // for animation
    BOOL            isAnimation;
    PHSessionView * topSession;
    PHSessionView * middleSession;
    PHSessionView * bottomSession;
    
    NSMutableDictionary * lastIndexInSession;
    
    /* @[ // session 0
        @{@(0) : thumbnail image 0,@(1) : thumbnail image 1},
          // session 1
        @{@(0) : thumbnail image 0,@(1) : thumbnail image 1},
        ]
     */
    NSArray * thumbnailImages;
    
    /* @[ // session 0
     @{@(0) : view controller 0,@(1) : view controller 1},
     // session 1
     @{@(0) : view controller 0,@(1) : view controller 1},
     ]
     */
    NSArray * viewControllers;
}

@synthesize contentView = _contentView, airImageView = _airImageView;

- (instancetype)initWithRootViewController:(UIViewController *)viewController atIndexPath:(NSIndexPath *)indexPath
{
    return [self initWithRootViewController:viewController atIndexPath:indexPath appearanceLayout:[PHAirViewAppearanceLayout debuggingAppearanceLayout]];
}

- (instancetype)initWithRootViewController:(UIViewController*)viewController
                     atIndexPath:(NSIndexPath*)indexPath
                appearanceLayout:(PHAirViewAppearanceLayout *)appearanceLayout
{
    if (self = [super init]) {
        _appearanceLayout = appearanceLayout;
        CGRect rect = [UIScreen mainScreen].applicationFrame;
        self.view.frame = CGRectMake(0, 0, rect.size.width, rect.size.height);
        [self bringViewControllerToTop:viewController
                           atIndexPath:indexPath];
        _appearanceLayout = appearanceLayout;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)]) {
        [self setEdgesForExtendedLayout:NO];
    }
    
    // Init sessionViews
    sessionViews = [NSMutableDictionary dictionary];
    currentIndexSession = 0;
    
    lastIndexInSession = [NSMutableDictionary dictionary];
    lastIndexInSession[@(0)] = @(0);
    self.currentIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    
    // Set delegate & dataSource
    self.delegate = self;
    self.dataSource = self;
    
    // Init contentView
    [self.view addSubview:self.wrapperView];
    [self.wrapperView addSubview:self.contentView];
    
    // Init left/rightView
    [self.leftViewWrapper addSubview:self.leftView];
    [self.contentView addSubview:self.leftViewWrapper];
    [self.contentView addSubview:self.rightView];
  
  
    // Init debugging coloring
    self.leftView.backgroundColor = _appearanceLayout.leftViewDebuggingColor;
    self.rightView.backgroundColor = _appearanceLayout.rightViewDebuggingColor;

    // Init airImageView
    [self.rightView addSubview:self.airImageView];
    
    // Init root view controller
    if ( self.storyboard) {
        @try {
            [self performSegueWithIdentifier:PHSegueRootIdentifier sender:nil];
        }
        @catch(NSException *exception) {}
    }
    
    // Init gestureRecognizer on airImageView
    self.interactAirViewPanGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(_handlePanGestureToRevealOnAirImageView:)];
    self.airViewTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_handleTapOnAirImageView:)];
    
    [self.airImageView addGestureRecognizer:self.interactAirViewPanGestureRecognizer];
    [self.airImageView addGestureRecognizer:self.airViewTapGestureRecognizer];
    
    // Init panGestureRecognizer for scroll on sessionViews
    self.scrollLeftViewPanGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(_handleScrollGestureOnLeftView:)];
    self.scrollLeftViewPanGestureRecognizer.delegate = self;
    [self.leftView addGestureRecognizer:self.scrollLeftViewPanGestureRecognizer];

    
    // Setup animation
    [self setupAnimation];
    
    self.leftView.alpha = 0;
    self.rightView.alpha = 0;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // layout menu
    [self reloadData];
}

- (void)bringViewControllerToTop:(UIViewController*)controller atIndexPath:(NSIndexPath*)indexPath
{
    if (!controller) return;
    
    // remove from super view
    if (self.frontViewController && self.frontViewController.view.superview) {
        [self.frontViewController removeFromParentViewController];
        [self.frontViewController.view removeFromSuperview];
    }
    
    // save information
    _frontViewController = controller;
    _currentIndexPath   = indexPath;
    
    if (indexPath && indexPath.row != kIndexPathOutMenu.row) {
        lastIndexInSession[@(indexPath.section)] = @(indexPath.row);
        
        // Save view controller
        [self saveViewControler:controller atIndexPath:indexPath];
    }
    
    // move to top
//    [_frontViewController viewWillAppear:YES];
//    [_frontViewController viewDidAppear:YES];
    
    [self addChildViewController:_frontViewController];
    UIView * controllerView = _frontViewController.view;
    controllerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    controllerView.frame = self.view.bounds;
    [self.view addSubview:controllerView];
    [_frontViewController didMoveToParentViewController:self];
}

#pragma mark storyboard support

- (void)prepareForSegue:(PHAirViewControllerSegue *)segue sender:(id)sender
{
    if ( [segue isKindOfClass:[PHAirViewControllerSegue class]] && sender == nil )
    {
        NSIndexPath * nextIndexPath = self.currentIndexPath;
        if ([segue.identifier isEqualToString:PHSegueRootIdentifier]) {
            if (self.delegate && [self.delegate respondsToSelector:@selector(indexPathDefaultValue)]) {
                nextIndexPath = [self.delegate indexPathDefaultValue];
            }
        }
        segue.performBlock = ^(PHAirViewControllerSegue* rvc_segue, UIViewController* svc, UIViewController* dvc)
        {
            [self bringViewControllerToTop:dvc atIndexPath:nextIndexPath];
        };
    }
}

#pragma mark - ContentView

- (void)contentViewDidTap:(UITapGestureRecognizer *)recognizer
{
    if (_airImageView.tag == 1) {

    }
}

#pragma mark - Gesture Delegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if (isAnimation) {
        return NO;
    }
    // only allow gesture if no previous request is in process
    //return ( gestureRecognizer == self.scrollLeftViewPanGestureRecognizer && !isAnimation) ;
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldBeRequiredToFailByGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return otherGestureRecognizer == self.interactAirViewPanGestureRecognizer;
}

#pragma mark - AirImageView gesture

- (void)_handleSwipeOnAirImageView:(UISwipeGestureRecognizer*)swipe
{
    [self hideAirViewOnComplete:^{
        [self bringViewControllerToTop:self.frontViewController
                           atIndexPath:self.currentIndexPath];
    }];
}

- (void)_handleTapOnAirImageView:(UITapGestureRecognizer*)swipe
{
    [self hideAirViewOnComplete:^{
        [self bringViewControllerToTop:self.frontViewController
                           atIndexPath:self.currentIndexPath];
    }];
}

- (void)_handlePanGestureToRevealOnAirImageView:(UIPanGestureRecognizer *)recognizer
{
    switch (recognizer.state)
    {
        case UIGestureRecognizerStateBegan:
            [recognizer setTranslation:CGPointZero inView:self.view];
            _previousRightViewOpenInteractionInPercent = 1.0;
            break;
        case UIGestureRecognizerStateChanged: {
            CGPoint translatedPoint = [recognizer translationInView:self.view];
            CGFloat percentIncreaseDelta = translatedPoint.x / _appearanceLayout.interactiveGestureBaseValueInPixel;
            _previousRightViewOpenInteractionInPercent += percentIncreaseDelta;

            [self _openAirViewInPercent:_previousRightViewOpenInteractionInPercent];
            self.leftView.alpha = _previousRightViewOpenInteractionInPercent;
            [recognizer setTranslation:CGPointZero inView:self.view];
        }
            break;
        case UIGestureRecognizerStateEnded:
            if (_previousRightViewOpenInteractionInPercent > kInteractiveRightViewSnapBackInPercent) {
              // snap back
                [UIView animateWithDuration:kDuration * (1 - _previousRightViewOpenInteractionInPercent) animations:^{
                    [self _openAirViewInPercent:1.0];
                    self.leftView.alpha = 1.0;
                }];
            } else {
                // open the view
                [self _hideAirViewWithDuration:kDuration * _previousRightViewOpenInteractionInPercent onComplete:^{
                    [self bringViewControllerToTop:self.frontViewController
                                       atIndexPath:self.currentIndexPath];
                }];

            }
            break;
        case UIGestureRecognizerStateCancelled:
            break;
        default:
            break;
    }
}

#pragma mark - Gesture Based Reveal

- (void)_handleScrollGestureOnLeftView:(UIPanGestureRecognizer *)recognizer
{
    if (sessionViews.count == 0 || sessionViews.count == 1) {
        return;
    }
    
    switch ( recognizer.state )
    {
        case UIGestureRecognizerStateBegan:
            [self handleRevealGestureStateBeganWithRecognizer:recognizer];
            break;
            
        case UIGestureRecognizerStateChanged:
            [self handleRevealGestureStateChangedWithRecognizer:recognizer];
            break;
            
        case UIGestureRecognizerStateEnded:
            [self handleRevealGestureStateEndedWithRecognizer:recognizer];
            break;
            
        case UIGestureRecognizerStateCancelled:
            [self handleRevealGestureStateCancelledWithRecognizer:recognizer];
            break;
        default:
            break;
    }
}

- (void)handleRevealGestureStateBeganWithRecognizer:(UIPanGestureRecognizer *)recognizer
{
}

- (void)handleRevealGestureStateChangedWithRecognizer:(UIPanGestureRecognizer *)recognizer
{
    CGFloat translation = [recognizer translationInView:self.leftView].y;
    self.leftView.top = -(self.view.height - _appearanceLayout.heightAirMenuSection) + translation;
    
    // Vị trí y của contentView khi ở chế độ bình thường
    int firstTop = - (self.view.height - _appearanceLayout.heightAirMenuSection);
    // Vị trí y hiện tại của contentView khi scroll
    int afterTop = self.leftView.top;
    
    // Điểm center bình thường của contentView : self.view.height/2
    // Khi scroll lên và scroll xuống thì độ chênh lệch của contentView là self.view.height/2
    
    int sessionViewHeight = self.view.height - _appearanceLayout.heightAirMenuSection;
    int distanceScroll = 0;
    // Nếu là kéo xuống
    if (afterTop - firstTop > 0) {
        int topMiddleSessionView = self.leftView.top + sessionViewHeight + 40;
        // Nếu điểm top của middleSession trên contentView nằm phía trên của giữa màn hình (theo trục y)
        if (topMiddleSessionView < self.view.height/2) {
            distanceScroll = self.view.height/2 - topMiddleSessionView;
        }
        // Nếu điểm top của middleSession trên contentView nằm phía dưới của giữa màn hình (theo trục y)
        else {
            distanceScroll = topMiddleSessionView - self.view.height/2 + 40;
        }
    }
    // Nếu là kéo lên
    else {
        int bottomMiddleSessionView = self.leftView.top + sessionViewHeight*2;
        if (bottomMiddleSessionView > self.view.height/2) {
            distanceScroll = bottomMiddleSessionView - self.view.height/2;
        } else {
            distanceScroll = self.view.height/2 - bottomMiddleSessionView;
        }
    }
    
    distanceScroll = abs(self.view.height/2 - distanceScroll);
    
    // Tính độ xoay
    // 0 tương ứng 0
    // distanceScroll ---> ?
    // max : self.view.height/2 tương ứng với abs(kDegressRotateToOut - kDegreesRotate)
    float rotateDegress = (distanceScroll * abs(kAirImageViewRotateMax - kAirImageViewRotate))/(self.view.height/2);
    self.lastDeegreesRotateTransform = rotateDegress;
    
    // Rotate airImageView
    CATransform3D airImageRotate = CATransform3DIdentity;
    airImageRotate = CATransform3DRotate(airImageRotate, AirDegreesToRadians(kAirImageViewRotate - rotateDegress), 0, 1, 0);
    self.airImageView.layer.transform = airImageRotate;
}

- (void)handleRevealGestureStateEndedWithRecognizer:(UIPanGestureRecognizer *)recognizer
{
    if (sessionViews.count == 0) {
        return;
    }
    
    // Vị trí y của contentView khi ở chế độ bình thường
    int firstTop = - (self.view.height - _appearanceLayout.heightAirMenuSection);
    // Vị trí y hiện tại của contentView khi scroll
    int afterTop = self.leftView.top;
    
    CGPoint velocity = [recognizer velocityInView:recognizer.view];
    
    // Nếu là kéo xuống
    if (afterTop - firstTop > 0) {
        if (afterTop - firstTop > self.view.height/2 - 40 || ABS(velocity.y) > 100) {
            // Đã kéo đủ một chiều cao cần thiết
            // Run animation down to next
            [self prevSession];
        } else {
            // Chưa kéo đủ một chiều cao cần thiết
            // Run animation up with current
            [self slideCurrentSession];
        }
    }
    // Nếu là kéo lên
    else {
        if (firstTop - afterTop > self.view.height/2 - 40 || ABS(velocity.y) > 100) {
            // Run animation up to next
            [self nextSession];
        }  else {
            // Run animation down with current
            [self slideCurrentSession];
        }
    }
}

- (void)handleRevealGestureStateCancelledWithRecognizer:(UIPanGestureRecognizer *)recognizer
{
}

#pragma mark -

- (void)nextSession
{
    // Next index
    currentIndexSession ++;
    if (currentIndexSession >= sessionViews.count) {
        currentIndexSession = 0;
    }
    
    // Get thumbnailImage
    NSIndexPath * lastIndexInThisSession = [NSIndexPath indexPathForRow:[lastIndexInSession[@(currentIndexSession)] intValue]
                                                              inSection:currentIndexSession];
    UIImage * nextThumbnail = [self getThumbnailImageAtIndexPath:lastIndexInThisSession];
    if (nextThumbnail) {
        self.airImageView.image = nextThumbnail;
    }
    
    // Animation
    [UIView animateWithDuration:0.2
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^
    {
        self.leftView.top = -(self.leftView.height/3)*2;
    } completion:^(BOOL finished) {
        [self layoutContaintView];
    }];
    [self rotateAirImage];
}

- (void)prevSession
{
    // Prev index
    currentIndexSession --;
    if (currentIndexSession < 0) {
        currentIndexSession = sessionViews.count - 1;
    }
    
    // Get thumbnailImage
    NSIndexPath * lastIndexInThisSession = [NSIndexPath indexPathForRow:[lastIndexInSession[@(currentIndexSession)] intValue]
                                                              inSection:currentIndexSession];
    UIImage * prevThumbnail = [self getThumbnailImageAtIndexPath:lastIndexInThisSession];
    if (prevThumbnail) {
        self.airImageView.image = prevThumbnail;
    }
    
    [UIView animateWithDuration:0.2
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^
     {
         self.leftView.top = 0;
     } completion:^(BOOL finished) {
         [self layoutContaintView];
     }];
    [self rotateAirImage];
}

- (void)slideCurrentSession
{
    [UIView animateWithDuration:0.2
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^
     {
         self.leftView.top = -self.leftView.height/3;
     } completion:^(BOOL finished) {
     }];
    [self rotateAirImage];
}

- (void)rotateAirImage
{
    if (self.lastDeegreesRotateTransform > 0) {
        [UIView animateWithDuration:0.2 animations:^{
            CATransform3D airImageRotate = self.airImageView.layer.transform;
            airImageRotate = CATransform3DRotate(airImageRotate, AirDegreesToRadians(self.lastDeegreesRotateTransform), 0, 1, 0);
            self.airImageView.layer.transform = airImageRotate;
        }completion:^(BOOL finished) {
            self.lastDeegreesRotateTransform = 0;
        }];
    } else {
        
        float rotateDegress = abs(kAirImageViewRotateMax - kAirImageViewRotate);
        
        [UIView animateWithDuration:0.15 animations:^{
            CATransform3D airImageRotate = self.airImageView.layer.transform;
            airImageRotate = CATransform3DRotate(airImageRotate, AirDegreesToRadians(-rotateDegress), 0, 1, 0);
            self.airImageView.layer.transform = airImageRotate;
        }completion:^(BOOL finished) {
            [UIView animateWithDuration:0.15 animations:^{
                CATransform3D airImageRotate = self.airImageView.layer.transform;
                airImageRotate = CATransform3DRotate(airImageRotate, AirDegreesToRadians(rotateDegress), 0, 1, 0);
                self.airImageView.layer.transform = airImageRotate;
            }completion:^(BOOL finished) {
                self.lastDeegreesRotateTransform = 0;
            }];
        }];
    }
}

#pragma mark - layout menu

- (void)reloadData
{
    if (!self.dataSource) return;
    
    // Get number session
    session = [self.dataSource numberOfSession];
  
    // leftViewWrapper
    self.leftViewWrapper.scrollEnabled = session == 1 && _appearanceLayout.enableLeftViewBouncinessWithOnlyOneSession;
    self.scrollLeftViewPanGestureRecognizer.enabled = session > 1;

    // Init
    NSMutableArray * tempThumbnails = [NSMutableArray array];
    NSMutableArray * tempViewControllers = [NSMutableArray array];
    for (int i = 0 ; i < session; i ++) {
        [tempThumbnails addObject:[NSMutableDictionary dictionary]];
        [tempViewControllers addObject:[NSMutableDictionary dictionary]];
    }
    thumbnailImages = [NSArray arrayWithArray:tempThumbnails];
    viewControllers = [NSArray arrayWithArray:tempViewControllers];

    
    // Get number rows of session
    NSMutableArray * temp = [NSMutableArray array];
    for (int i = 0; i < session; i ++) {
        [temp addObject:@([self.dataSource numberOfRowsInSession:i])];
    }
    rowsOfSession = [NSArray arrayWithArray:temp];
    
    // Init PHSessionView
    int sessionHeight = self.view.frame.size.height - _appearanceLayout.heightAirMenuSection;
    for (int i = 0; i < session; i ++) {
        PHSessionView * sessionView = sessionViews[@(i)];
        if (!sessionView) {
            sessionView = [[PHSessionView alloc] initWithFrame:CGRectMake(_appearanceLayout.sessionViewLeftPadding, 0, kSessionWidth, sessionHeight)];
            [sessionView.titleButton setTitleColor:_appearanceLayout.sectionTitleColor forState:UIControlStateNormal];
            sessionView.titleButton.titleLabel.font = _appearanceLayout.sectionTitleFont;
            sessionView.titleButton.tag = i;
            [sessionView.titleButton addTarget:self action:@selector(sessionButtonTouch:) forControlEvents:UIControlEventTouchUpInside];
            CGFloat buttonY = 0;
            switch (_appearanceLayout.sectionContentMode) {
                case PHAirViewAppearanceLayoutContentModeTop:
                    buttonY = _appearanceLayout.sectionEdgeInsets.top;
                    break;
                case PHAirViewAppearanceLayoutContentModeCenter:
                    buttonY = (_appearanceLayout.heightAirMenuSection - _appearanceLayout.sectionContentHeight) / 2;
                    break;
                case PHAirViewAppearanceLayoutContentModeBottom:
                    buttonY = _appearanceLayout.heightAirMenuSection - _appearanceLayout.sectionContentHeight - _appearanceLayout.sectionEdgeInsets.bottom;
                    break;
            }
            sessionView.titleButton.constrainImage = YES;
            sessionView.titleButton.frame = CGRectMake(_appearanceLayout.sectionEdgeInsets.left, buttonY, kSessionWidth, _appearanceLayout.sectionContentHeight);
            [sessionViews setObject:sessionView forKey:@(i)];
        }
        // Set title for header session
        NSString * sesionTitle = [self.dataSource titleForHeaderAtSession:i];
        [sessionView.titleButton setTitle:sesionTitle forState:UIControlStateNormal];
        
        if ([self.dataSource respondsToSelector:@selector(thumbnailForHeaderAtSession:)]) {
            [sessionView.titleButton setImageForSingleState:[self.dataSource thumbnailForHeaderAtSession:i]];
            sessionView.titleButton.titleImagePadding = _appearanceLayout.paddingBetweenThumbnailAndTitleInSection;
        }
    }
    
    // Init menu item for session
    for (int i = 0; i < session; i ++) {
        PHSessionView * sessionView = sessionViews[@(i)];
        sessionView.containView.frame = CGRectMake(0, _appearanceLayout.heightAirMenuSection, kSessionWidth, sessionHeight - _appearanceLayout.heightAirMenuSection);
        // Remove all sub-view for contain of PHSessionView
        for (UIView * view in sessionView.containView.subviews) {
            [view removeFromSuperview];
        }


        CGFloat buttonY = 0;
        switch (_appearanceLayout.rowsContentMode) {
            case PHAirViewAppearanceLayoutContentModeCenter:
                buttonY = MAX(0, (sessionView.containView.frame.size.height - [rowsOfSession[i] intValue] * _appearanceLayout.heightAirMenuRow - ([rowsOfSession[i] intValue] - 1) * _appearanceLayout.paddingBetweenRows) / 2);
                break;
            case PHAirViewAppearanceLayoutContentModeBottom:
            case PHAirViewAppearanceLayoutContentModeTop:
                buttonY = _appearanceLayout.rowsEdgeInsets.top;
                break;
        }
        for (int j = 0; j < [rowsOfSession[i] intValue]; j ++) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:j inSection:i];
            NSString * title = [self.dataSource titleForRowAtIndexPath:indexPath];
            PPImageTitleButton * button = [[PPImageTitleButton alloc] initWithFrame:CGRectZero];
            [button setTitle:title forState:UIControlStateNormal];
            [button addTarget:self action:@selector(rowDidTouch:) forControlEvents:UIControlEventTouchUpInside];
            [button setTitleColor:_appearanceLayout.titleNormalColor forState:UIControlStateNormal];
            [button setTitleColor:_appearanceLayout.titleHighlightColor forState:UIControlStateHighlighted];
            [button setTitleColor:_appearanceLayout.titleSelectedColor forState:UIControlStateSelected];
            button.titleLabel.font = _appearanceLayout.rowTitleFont;
            button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
            button.constrainImage = YES;
            if ([self.dataSource respondsToSelector:@selector(thumbnailForRowAtIndexPath:)]) {
                [button setImage:[self.dataSource thumbnailForRowAtIndexPath:indexPath] forState:UIControlStateNormal];
                button.titleImagePadding = _appearanceLayout.paddingBetweenThumbnailAndTitleInRow;
            }
            [button sizeToFit];
            button.frame = CGRectMake(_appearanceLayout.rowsEdgeInsets.left, buttonY, MIN(CGRectGetWidth(button.bounds), 200), _appearanceLayout.heightAirMenuRow);
            button.tag = j;
            sessionView.containView.tag = i;
            [sessionView.containView addSubview:button];
            
            buttonY += _appearanceLayout.heightAirMenuRow + _appearanceLayout.paddingBetweenRows;
        }
    }
    
    // layout content view
    [self layoutContaintView];
}

- (void)layoutContaintView
{
    if (sessionViews.count == 1) {
        middleSession = sessionViews[@(0)];
        topSession = nil;
        bottomSession = nil;
        
        middleSession.top = middleSession.height;
        [self.leftView addSubview:middleSession];
        self.leftView.top = - (self.leftView.height)/3;        
        
        // Update color
        [self updateButtonColor];
        return;
    }
    
    if (topSession.superview) {
        [topSession removeFromSuperview];
        topSession = nil;
    }
    if (middleSession.superview) {
        [middleSession removeFromSuperview];
        middleSession = nil;
    }
    if (bottomSession.superview) {
        [bottomSession removeFromSuperview];
        bottomSession = nil;
    }
    
    // Init top/middle/bottom session view
    if (sessionViews.count == 1) {
        middleSession = sessionViews[@(0)];
        topSession = (PHSessionView*)[self duplicate:middleSession];
        bottomSession = (PHSessionView*)[self duplicate:middleSession];
    } else if(sessionViews.count == 2) {
        middleSession = sessionViews[@(currentIndexSession)];
        if (currentIndexSession == 0) {
            topSession = (PHSessionView*)[self duplicate:sessionViews[@(1)]];
            bottomSession = sessionViews[@(1)];
        } else {
            topSession = (PHSessionView*)[self duplicate:sessionViews[@(0)]];
            bottomSession = sessionViews[@(0)];
        }
    } else {
        middleSession = sessionViews[@(currentIndexSession)];
        if (currentIndexSession == 0) {
            topSession = sessionViews[@(sessionViews.count - 1)];
        } else {
            topSession = sessionViews[@(currentIndexSession - 1)];
        }
        if (currentIndexSession + 1 >= sessionViews.count) {
            bottomSession = sessionViews[@(0)];
        } else {
            bottomSession = sessionViews[@(currentIndexSession + 1)];
        }
    }
    
    // Pos for top/middle/bottom session
    topSession.top    = 0;
    middleSession.top = topSession.bottom;
    bottomSession.top = middleSession.bottom;
    
    // Add top/middle/bottom to content view
    [self.leftView addSubview:topSession];
    [self.leftView addSubview:middleSession];
    [self.leftView addSubview:bottomSession];
    
    self.leftView.top = - (self.leftView.height)/3;
    
    // Update color
    [self updateButtonColor];
}

- (void)updateButtonColor
{
    for (int i = 0 ; i < sessionViews.count; i ++) {
        PHSessionView * sessionView = sessionViews[@(i)];
        // Dòng đã touch cuối cùng trong session i
        int indexHighlight = [lastIndexInSession[@(i)] intValue];
        //
        for (id object in sessionView.containView.allSubviews) {
            if ([object isKindOfClass:[UIButton class]]) {
                UIButton * button = object;
                button.selected = (button.tag == indexHighlight) ? YES : NO;
            }
        }
    }
}

#pragma mark - PHAirMenuDelegate

- (NSInteger)numberOfSession { return 0; }

- (NSInteger)numberOfRowsInSession:(NSInteger)sesion { return  0; }

- (NSString*)titleForHeaderAtSession:(NSInteger)session { return @""; }

- (NSString*)titleForRowAtIndexPath:(NSIndexPath*)indexPath { return @""; }

#pragma mark - Button action

- (void)sessionButtonTouch:(UIButton*)button
{
    if (button.tag == currentIndexSession) {
        return;
    } else {
        [self nextSession];
    }
}

- (void)rowDidTouch:(UIButton*)button
{
    NSIndexPath *selectedIndexPath = [NSIndexPath indexPathForRow:button.tag inSection:button.superview.tag];
    // Should select ?
    if (self.delegate && [self.delegate respondsToSelector:@selector(shouldSelectRowAtIndex:)]) {
        if (![self.delegate shouldSelectRowAtIndex:selectedIndexPath]) {
            return;
        }
    }
  
    // Save row touch in session
    lastIndexInSession[@(currentIndexSession)] = @(button.tag);
    self.currentIndexPath = selectedIndexPath;
  
    if (self.delegate && [self.delegate respondsToSelector:@selector(didSelectRowAtIndex:)]) {
        [self.delegate didSelectRowAtIndex:self.currentIndexPath];
    }
  
    [self updateButtonColor];

    // Get thumbnailImage
    UIImage * nextThumbnail = [self getThumbnailImageAtIndexPath:self.currentIndexPath];
    if (nextThumbnail) {
        self.airImageView.image = nextThumbnail;
    }
    
    [self hideAirViewOnComplete:^{
        UIViewController * controller = [self getViewControllerAtIndexPath:self.currentIndexPath];
        if (controller) {
            [self bringViewControllerToTop:controller atIndexPath:self.currentIndexPath];
        } else if (self.storyboard) {
            // Ưu tiên sử dụng storyboard
            if (self.dataSource && [self.dataSource respondsToSelector:@selector(segueForRowAtIndexPath:)]) {
                NSString * segue = [self.dataSource segueForRowAtIndexPath:self.currentIndexPath];
                if (segue.length) {
                    @try {
                        [self performSegueWithIdentifier:segue sender:nil];
                    }
                    @catch(NSException *exception) {}
                }
            } else {
                // Sử dụng viewController
                if (self.dataSource && [self.dataSource respondsToSelector:@selector(viewControllerForIndexPath:)]) {
                    UIViewController * controller = [self.dataSource viewControllerForIndexPath:self.currentIndexPath];
                    [self bringViewControllerToTop:controller atIndexPath:self.currentIndexPath];
                }
            }
        } else {
            UIViewController * controller = [self.dataSource viewControllerForIndexPath:self.currentIndexPath];
            [self bringViewControllerToTop:controller atIndexPath:self.currentIndexPath];
        }
    }];
}

#pragma mark - property

- (UIView*)wrapperView
{
    if (!_wrapperView) {
        _wrapperView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.width,self.view.height)];
    }
    return _wrapperView;
}

- (UIView*)contentView
{
    if (!_contentView) {
        _contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.width,self.view.height)];
    }
    return _contentView;
}

- (UIImageView*)airImageView
{
    if (!_airImageView) {
        _airImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.view.width, self.view.height)];
        _airImageView.userInteractionEnabled = YES;
    }
    return _airImageView;
}

- (UIView*)leftView
{
    if (!_leftView) {
        // leftView content sessionView
        _leftView = [[UIView alloc] initWithFrame:CGRectMake(0, -(self.view.height - _appearanceLayout.heightAirMenuSection), kSessionWidth, (self.view.height - _appearanceLayout.heightAirMenuSection)*3)];
        _leftView.userInteractionEnabled = YES;
    }
    return _leftView;
}

- (UIScrollView *)leftViewWrapper
{
  if (!_leftViewWrapper) {
    _leftViewWrapper = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, kSessionWidth, CGRectGetHeight(self.view.bounds))];
    _leftViewWrapper.alwaysBounceVertical = YES;
    _leftViewWrapper.scrollsToTop = NO; // disable tapping status that allow it to scrollToTop
  }
  return _leftViewWrapper;
}

- (UIView*)rightView
{
    if (!_rightView) {
        _rightView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.width, self.view.height)];
        _rightView.userInteractionEnabled = YES;
    }
    return _rightView;
}

- (void)_resetLeftViewFrame
{
  // BUG: There is a bug in the translation of the leftView.layer.transform. Too hard to fix. Thus need to reset it its frame
  _leftView.layer.transform = CATransform3DIdentity;
  _leftView.frame = CGRectMake(0, -(self.view.height - _appearanceLayout.heightAirMenuSection), kSessionWidth, (self.view.height - _appearanceLayout.heightAirMenuSection)*3);
}
#pragma mark - Show/Hide air view controller

- (void)showAirViewFromViewController:(UIViewController*)controller
                             complete:(void (^)(void))complete
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(willShowAirViewController)]) {
        [self.delegate willShowAirViewController];
    }
    
    // Create Image for airImageView (either from dataSource or manually generate)
    if ([self.dataSource respondsToSelector:@selector(viewControllerSnapshotAtIndexPath:)]) {
        _airImageView.image = [self.dataSource viewControllerSnapshotAtIndexPath:self.currentIndexPath];
    } else {
        _airImageView.image = [self imageWithView:controller.view];
    }
    
    // Save thumbnail
    [self saveThumbnailImage:_airImageView.image atIndexPath:self.currentIndexPath];
    // Save viewController
    [self saveViewControler:controller atIndexPath:self.currentIndexPath];
    
    // Fix for touch and pan
    [self.view bringSubviewToFront:self.wrapperView];
    [self.contentView bringSubviewToFront:self.leftView];
    [self.contentView bringSubviewToFront:self.rightView];
    
    // Remove font view controller
    if (controller) {
        [controller removeFromParentViewController];
        [controller.view removeFromSuperview];
    }
  
    [self _resetLeftViewFrame];
    [self _openAirViewInPercent:0.0];
    
    self.rightView.alpha = 1;
    self.leftView.alpha  = 0;
    _showAirView = YES;

    // update UI
    [self updateButtonColor];

    [UIView animateWithDuration:kDuration
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^
     {
        [self setNeedsStatusBarAppearanceUpdate];
         self.leftView.alpha = 1;
        [self _openAirViewInPercent:1.0];
     } completion:^(BOOL finished) {
         if (complete) complete();
     }];
    
    _airImageView.tag = 1;
}

- (void)switchToViewController:(UIViewController*)controller atIndexPath:(NSIndexPath*)indexPath
{
    [self bringViewControllerToTop:controller
                       atIndexPath:indexPath];
}

- (void)switchToViewController:(UIViewController*)controller
{
    [self bringViewControllerToTop:controller
                       atIndexPath:kIndexPathOutMenu];
}

- (void)hideAirViewOnComplete:(void (^)(void))complete
{
    [self _hideAirViewWithDuration:kDuration onComplete:complete];
}

- (void)_hideAirViewWithDuration:(NSTimeInterval)duration onComplete:(void (^)(void))complete
{
    _showAirView = NO;
    if (self.delegate && [self.delegate respondsToSelector:@selector(willHideAirViewController)]) {
        [self.delegate willHideAirViewController];
    }
    
    [UIView animateWithDuration:duration
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^
     {
       [self setNeedsStatusBarAppearanceUpdate];
       
       self.leftView.alpha = 0;
       [self _openAirViewInPercent:0.0];
     } completion:^(BOOL finished) {
         self.rightView.alpha = 0;
         if (self.delegate && [self.delegate respondsToSelector:@selector(didHideAirViewController)]) {
             [self.delegate didHideAirViewController];
         }
         
         if (complete) {
             complete();
         }
     }];
    
    _airImageView.tag = 0;
}

#pragma mark - animation

- (void)setupAnimation
{
    // Setup airImageView to transform
    CATransform3D rotationAndPerspectiveTransform = CATransform3DIdentity;
    rotationAndPerspectiveTransform.m34 = 1.0 / -600;
    self.rightView.layer.sublayerTransform = rotationAndPerspectiveTransform;
    CGPoint anchorPoint = CGPointMake(1, 0.5);
    CGFloat newX = _airImageView.width * anchorPoint.x;
    CGFloat newY = _airImageView.height * anchorPoint.y;
    _airImageView.layer.position = CGPointMake(newX, newY);
    _airImageView.layer.anchorPoint = anchorPoint;
    
    // Setup rightView to transform
    CATransform3D rotationAndPerspectiveTransform2 = CATransform3DIdentity;
    rotationAndPerspectiveTransform2.m34 = 1.0 / -600;
    self.contentView.layer.sublayerTransform = rotationAndPerspectiveTransform2;
    CGPoint anchorPoint2 = CGPointMake(1, 0.5);
    CGFloat newX2 = self.rightView.width * anchorPoint2.x;
    CGFloat newY2 = self.rightView.height * anchorPoint2.y;
    self.rightView.layer.position = CGPointMake(newX2, newY2);
    self.rightView.layer.anchorPoint = anchorPoint2;
    
    // Setup leftView to transform
    CGPoint leftAnchorPoint = CGPointMake(-3, 0.5);
    CGFloat newLeftX = self.leftView.width * leftAnchorPoint.x;
    CGFloat newLeftY = self.leftView.height * leftAnchorPoint.y;
    self.leftView.layer.position = CGPointMake(newLeftX, newLeftY);
    self.leftView.layer.anchorPoint = leftAnchorPoint;
    
    // Setup contentView to transform
    /*
    CATransform3D rotationAndPerspectiveTransform3 = CATransform3DIdentity;
    rotationAndPerspectiveTransform3.m34 = 1.0 / -600;
    self.wrapperView.layer.sublayerTransform = rotationAndPerspectiveTransform3;
     */
    
    CGPoint anchorPoint3 = CGPointMake(1, 0.5);
    CGFloat newX3 = self.contentView.width * anchorPoint3.x;
    CGFloat newY3 = self.contentView.height * anchorPoint3.y;
    self.contentView.layer.position = CGPointMake(newX3, newY3);
    self.contentView.layer.anchorPoint = anchorPoint3;
}

// 0% means close. 100% means completely open
- (void)_openAirViewInPercent:(CGFloat)percent
{
    // airImageView rotate on Y
    self.airImageView.layer.transform = CATransform3DRotate(CATransform3DIdentity, AirDegreesToRadians(kAirImageViewRotate * percent), 0, 1, 0);
    
    // rightView move on Z
    self.rightView.layer.transform = CATransform3DTranslate(CATransform3DIdentity, kRightViewTransX * percent, 0, kRightViewTransZ * percent);
    
    // LeftView rotate on X and move on Y
    CGFloat inverseOfPercent = 1.0 - percent;
    CATransform3D leftTransform = CATransform3DIdentity;
    leftTransform = CATransform3DTranslate(leftTransform, kLeftViewTransX * inverseOfPercent, 0, 0);
    leftTransform = CATransform3DRotate(leftTransform, AirDegreesToRadians(kLeftViewRotate * inverseOfPercent), 0, 1, 0);
    self.leftView.layer.transform = leftTransform;
}

#pragma mark - Helper

// Get thumbnailImage of NSIndexPath
- (UIImage*)getThumbnailImageAtIndexPath:(NSIndexPath*)indexPath
{
    NSMutableDictionary * thumbnailDic = thumbnailImages[indexPath.section];
    if (thumbnailDic[@(indexPath.row)]) {
        return thumbnailDic[@(indexPath.row)];
    } else {
        if ([self.dataSource respondsToSelector:@selector(viewControllerSnapshotAtIndexPath:)]) {
            return [self.dataSource viewControllerSnapshotAtIndexPath:indexPath];
        }
    }
    return nil;
}

// Save thumbnailImage
- (void)saveThumbnailImage:(UIImage*)image atIndexPath:(NSIndexPath*)indexPath
{
    if (!image) return;
    
    NSMutableDictionary * thumbnailDic = thumbnailImages[indexPath.section];
    [thumbnailDic setObject:image forKey:@(indexPath.row)];
}

// Get viewController of NSIndexPath
- (UIViewController*)getViewControllerAtIndexPath:(NSIndexPath*)indexPath
{
    NSMutableDictionary * viewControllerDic = viewControllers[indexPath.section];
    if (viewControllerDic[@(indexPath.row)]) {
        return viewControllerDic[@(indexPath.row)];
    } else {
        if ([self.dataSource respondsToSelector:@selector(viewControllerForIndexPath:)]) {
            return [self.dataSource viewControllerForIndexPath:indexPath];
        }
    }
    return nil;
}

// Save viewController
- (void)saveViewControler:(UIViewController*)controller atIndexPath:(NSIndexPath*)indexPath
{
    if (!controller) return;
    
    NSMutableDictionary * viewControllerDic = viewControllers[indexPath.section];
    [viewControllerDic setObject:controller forKey:@(indexPath.row)];
}

// Take picture of UIView
- (UIImage*)imageWithView:(UIView*)view
{
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, NO, 0.0);
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage * img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img;
}

// Duplicate UIView
- (UIView*)duplicate:(UIView*)view
{
    NSData * tempArchive = [NSKeyedArchiver archivedDataWithRootObject:view];
    return [NSKeyedUnarchiver unarchiveObjectWithData:tempArchive];
}

#pragma mark - Clean up

- (void)dealloc
{
    [_airImageView removeFromSuperview];
    _airImageView = nil;
    [_rightView removeFromSuperview];
    _rightView = nil;
    
    [_leftView removeFromSuperview];
    _leftView = nil;
    
    [_contentView removeFromSuperview];
    _contentView = nil;
    [_wrapperView removeFromSuperview];
    _wrapperView = nil;
    
    rowsOfSession = nil;
    
    _scrollLeftViewPanGestureRecognizer.delegate = nil;
    [_scrollLeftViewPanGestureRecognizer removeTarget:self action:@selector(_handleScrollGestureOnLeftView:)];
    [_interactAirViewPanGestureRecognizer removeTarget:self action:@selector(_handlePanGestureToRevealOnAirImageView:)];
    [_airViewTapGestureRecognizer removeTarget:self action:@selector(_handleTapOnAirImageView:)];
}

#pragma mark - StatusBar
- (UIStatusBarStyle)preferredStatusBarStyle
{
  return _appearanceLayout.statusBarStyle;
}

- (BOOL)prefersStatusBarHidden
{
  return _appearanceLayout.statusBarHidden;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation
{
  return _appearanceLayout.statusBarAnimation;
}

- (UIViewController *)childViewControllerForStatusBarHidden
{
  if (!_showAirView) {
    if ([self.frontViewController isKindOfClass:[UINavigationController class]]) {
      return [(UINavigationController *)self.frontViewController topViewController];
    }
    return self.frontViewController;
  } else {
    // trigger prefersStatusBarHidden
    return nil;
  }
}

- (UIViewController *)childViewControllerForStatusBarStyle
{
  if (!_showAirView) {
    if ([self.frontViewController isKindOfClass:[UINavigationController class]]) {
      return [(UINavigationController *)self.frontViewController topViewController];
    }
    return self.frontViewController;
  } else {
    // trigger prefersStatusBarStyle
    return nil;
  }
}
@end


#pragma mark - UIViewController(PHAirViewController) Category

@implementation UIViewController(PHAirViewController)

#pragma mark - Property

static char const * const SwipeTagHandle = "SWIPE_HANDER";
static char const * const SwipeObject    = "SWIPE_OBJECT";

- (UISwipeGestureRecognizer*)phSwipeGestureRecognizer{
    UISwipeGestureRecognizer * swipe = objc_getAssociatedObject(self, SwipeObject);
    if (!swipe) {
        swipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeHanle)];
        swipe.direction = UISwipeGestureRecognizerDirectionRight;
        objc_setAssociatedObject(self, SwipeObject, swipe, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return swipe;
}

- (void)setPhSwipeHander:(void (^)(void))phSwipeHander
{
    if (phSwipeHander) {
        if (self.phSwipeGestureRecognizer.view) {
            [self.phSwipeGestureRecognizer.view removeGestureRecognizer:self.phSwipeGestureRecognizer];
        }
        
        if (self.navigationController) {
            [self.navigationController.view addGestureRecognizer:self.phSwipeGestureRecognizer];
        } else {
            [self.view addGestureRecognizer:self.phSwipeGestureRecognizer];
        }
        objc_setAssociatedObject(self, SwipeTagHandle, phSwipeHander, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    } else {
        if (self.phSwipeGestureRecognizer.view) {
            [self.phSwipeGestureRecognizer.view removeGestureRecognizer:self.phSwipeGestureRecognizer];
        }
    }
}

- (void (^)(void))phSwipeHander
{
    return objc_getAssociatedObject(self, SwipeTagHandle);
}

- (void)swipeHanle
{
    if (self.phSwipeHander) {
        self.phSwipeHander();
    }
}

- (PHAirViewController*)airViewController
{
    UIViewController *parent = self;
    Class revealClass = [PHAirViewController class];
    
    while ( nil != (parent = [parent parentViewController]) && ![parent isKindOfClass:revealClass] ) {}
    return (id)parent;
}

/// Fix the bug based on comment here: https://github.com/taphuochai/PHAirViewController/issues/13
/// This is so that phSwipeGestureRecognizer doesn't create a swipe gesture in *every* vc's dealloc.
- (BOOL)phSwipeGestureRecognizerExists {
    return objc_getAssociatedObject(self, SwipeObject) != nil;
}

- (void)ph_dealloc
{
    if (self.phSwipeGestureRecognizerExists) {
        self.phSwipeHander = nil;
    }
    [self ph_dealloc]; // This calls the original dealloc.
}

/// Swizzle the method into place.
void PH_MethodSwizzle(Class c, SEL origSEL, SEL overrideSEL) {
    Method origMethod = class_getInstanceMethod(c, origSEL);
    Method overrideMethod = class_getInstanceMethod(c, overrideSEL);
    if (class_addMethod(c, origSEL, method_getImplementation(overrideMethod), method_getTypeEncoding(overrideMethod))) {
        class_replaceMethod(c, overrideSEL, method_getImplementation(origMethod), method_getTypeEncoding(origMethod));
    } else {
        method_exchangeImplementations(origMethod, overrideMethod);
    }
}

/// Swizzle dealloc at load time.
+ (void)load {
    SEL deallocSelector = NSSelectorFromString(@"dealloc"); // Because ARC won't allow @selector(dealloc).
    PH_MethodSwizzle(self, deallocSelector, @selector(ph_dealloc));
}

@end


#pragma mark - PHAirViewControllerSegue Class

@implementation PHAirViewControllerSegue

- (void)perform
{
    if (_performBlock != nil) {
        _performBlock( self, self.sourceViewController, self.destinationViewController );
    }
}

@end
