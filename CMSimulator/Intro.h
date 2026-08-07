//
//  Intro.h
//  CMSimulator
//
//  Created by Enrique Galicia on 09/11/15.
//  Copyright © 2015 Enrique Galicia. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol introA;

@interface Intro : UIViewController{
    id<introA>delegado;
    IBOutlet UIImageView *playButton;
    IBOutlet UIImageView *helpButton;
    IBOutlet UIImageView *scoresButton;
}
@property (nonatomic, weak)id<introA>delegado;
@property (nonatomic)IBOutlet UIImageView *playButton;
@property (nonatomic)IBOutlet UIImageView *helpButton;
@property (nonatomic)IBOutlet UIImageView *scoresButton;

@end

@protocol introA
-(void)introPlay;
-(void)introHelp;
-(void)introScores;
@end
