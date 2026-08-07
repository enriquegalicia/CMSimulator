//
//  Result.h
//  CMSimulator
//
//  Created by Enrique Galicia on 05/11/15.
//  Copyright © 2015 Enrique Galicia. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol result;


@interface Result : UIViewController{
    id<result>deleresult;
    IBOutlet UILabel *LCost;
    IBOutlet UILabel *LTime;
    IBOutlet UITextField *TfNombre;
    IBOutlet UILabel *Save;
    float fcosto;
    float ftiempo;
}
@property(nonatomic)id<result>deleresult;
@property(nonatomic)IBOutlet UILabel *LCost;
@property(nonatomic)IBOutlet UILabel *LTime;
@property(nonatomic)IBOutlet UITextField *TfNombre;
@property(nonatomic)IBOutlet UILabel *Save;
@property(nonatomic,assign)float fcosto;
@property(nonatomic,assign)float ftiempo;

@end
@protocol result
-(void)resultado:(NSMutableDictionary*)arreglo;

@end;
