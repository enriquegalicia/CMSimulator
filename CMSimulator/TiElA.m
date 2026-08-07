//
//  Resultados Finales.m
//  Xvaluapp
//
//  Created by Enrique Galicia on 02/04/14.
//  Copyright (c) 2014 Enrique Galicia. All rights reserved.
//

#import "TiElA.h"

@implementation TiElA
@synthesize Id=_Id;
@synthesize Titulo=_Titulo;
@synthesize Subtitulo=_Subtitulo;



- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor=[UIColor clearColor];
        contentview.backgroundColor=[UIColor clearColor];


    }
    return self;
}
+ (NSString *)reuseIdentifier {
    return @"CellIdentifier";
}



- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}


@end
