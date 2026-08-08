//
//  Intro.m
//  CMSimulator
//
//  Created by Enrique Galicia on 09/11/15.
//  Copyright © 2015 Enrique Galicia. All rights reserved.
//

#import "Intro.h"
#import "UIViewController+CanvasFit.h"

@interface Intro ()

@end

@implementation Intro
@synthesize delegado, playButton, helpButton, scoresButton;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

-(void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    [self fitDesignCanvas:CGSizeMake(1024, 768)];
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    UITouch *touch = [touches anyObject];
    if ([touch view] == playButton) {
        [self.delegado introPlay];
    }
    else if ([touch view] == helpButton) {
        [self.delegado introHelp];
    }
    else if ([touch view] == scoresButton) {
        [self.delegado introScores];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
