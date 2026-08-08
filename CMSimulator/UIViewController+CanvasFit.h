//
//  UIViewController+CanvasFit.h
//  CMSimulator
//
//  Every screen in this app (ViewController, Intro, Result, Scores, Help)
//  was designed as a fixed-size 1024x768 landscape canvas with every
//  subview placed at an absolute pixel position (fixedFrame="YES" in the
//  storyboard/xib - no Auto Layout). That is exactly right for the iPad
//  it was built for, but on any other screen size (iPhone, a different
//  iPad, Slide Over) the canvas either overflows or leaves the wrong gaps.
//
//  Rather than re-authoring every screen's layout, this category scales
//  the whole canvas view uniformly to fit the current window - like a
//  fixed-resolution game rendered letterboxed on a different screen.
//  Every child view keeps its original relative position untouched.
//

#import <UIKit/UIKit.h>

@interface UIViewController (CanvasFit)

// Scales self.view (assumed to be a fixed-size, absolute-positioned canvas
// of `designSize`) to uniformly fit the current window bounds, centered.
// Call this from viewDidLayoutSubviews so it re-applies on rotation and
// on any host size change (iPhone vs iPad, Slide Over, Stage Manager).
-(void)fitDesignCanvas:(CGSize)designSize;

@end
