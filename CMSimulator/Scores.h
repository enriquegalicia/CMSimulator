//
//  Scores.h
//  CMSimulator
//
//  Created by Enrique Galicia on 05/11/15.
//  Copyright © 2015 Enrique Galicia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TiElTaA.h"

@protocol scorespro;
@interface Scores : UIViewController<restable5>{
    
    id<scorespro>delescore;
    TiElTaA *TaScores; 
    IBOutlet UIImageView *IvTaScores;
    
    IBOutlet UIImageView *IvCost;
    IBOutlet UIImageView *IvTime;
    IBOutlet UIImageView *IvMaster;
    IBOutlet UILabel *IvTitulo;
    IBOutlet UILabel *Exit;
    NSMutableDictionary *valores;
    
}
@property(nonatomic)id<scorespro>delescore;
@property(nonatomic)NSMutableDictionary *valores;
@property(nonatomic)TiElTaA *TaScores;
-(void)cargartablageneral:(NSMutableDictionary*)tabla;


@end
@protocol scorespro
-(NSMutableArray*)changescore:(NSString*)score;
-(NSMutableDictionary*)obtenerinformacion2;
-(void)exit;
@end
