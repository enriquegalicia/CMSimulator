//
//  Help.h
//  CMSimulator
//
//  Created by Enrique Galicia on 09/11/15.
//  Copyright © 2015 Enrique Galicia. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol helpopro;

@interface Help : UIViewController{
    id<helpopro>delehelpo;
}
@property(nonatomic)id<helpopro>delehelpo;

@end
@protocol helpopro
-(void)exithelp;

@end
