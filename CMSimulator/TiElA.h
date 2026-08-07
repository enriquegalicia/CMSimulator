//
//  Resultados Finales.h
//  Xvaluapp
//
//  Created by Enrique Galicia on 02/04/14.
//  Copyright (c) 2014 Enrique Galicia. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface TiElA : UITableViewCell{

    IBOutlet UIView *contentview;
    
}

+ (NSString *)reuseIdentifier;
@property(nonatomic,retain)NSString *Id;
@property(nonatomic,retain)IBOutlet UILabel *Num;

@property(nonatomic,retain)IBOutlet UILabel *Titulo;
@property(nonatomic,retain)IBOutlet UILabel *Subtitulo;

@end