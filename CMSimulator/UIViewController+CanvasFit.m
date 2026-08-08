//
//  UIViewController+CanvasFit.m
//  CMSimulator
//

#import "UIViewController+CanvasFit.h"

@implementation UIViewController (CanvasFit)

-(void)fitDesignCanvas:(CGSize)designSize{
    if (designSize.width<=0 || designSize.height<=0) { return; }

    CGRect targetBounds = self.view.window ? self.view.window.bounds : [UIScreen mainScreen].bounds;
    if (CGRectIsEmpty(targetBounds)) { return; }

    // Neutralize any previous transform before measuring/repositioning,
    // otherwise a stale scale from a prior orientation/size compounds.
    self.view.transform = CGAffineTransformIdentity;
    self.view.bounds = CGRectMake(0, 0, designSize.width, designSize.height);
    self.view.center = CGPointMake(CGRectGetMidX(targetBounds), CGRectGetMidY(targetBounds));

    CGFloat scale = MIN(targetBounds.size.width/designSize.width, targetBounds.size.height/designSize.height);
    if (scale>0) {
        self.view.transform = CGAffineTransformMakeScale(scale, scale);
    }

    // Fill the letterboxed margin (visible on any screen whose aspect
    // ratio differs from the 4:3 design canvas, e.g. iPhone) with black
    // instead of leaving whatever was behind the window showing through.
    if (self.view.window && self.view.window.backgroundColor==nil) {
        self.view.window.backgroundColor=[UIColor blackColor];
    }
}

@end
