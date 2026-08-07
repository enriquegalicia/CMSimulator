//
//  SPI.m
//  Clases
//
//  Created by Enrique Galicia on 15/08/13.
//  Copyright (c) 2013 MAG Architecture and Technology Solutions. All rights reserved.
//

#import "SPI.h"

@implementation SPI
@synthesize pspi;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}


- (void)drawRect:(CGRect)rect {
    
    
    CGContextRef context2 = UIGraphicsGetCurrentContext();
    CGRect drawRect = CGRectMake(rect.origin.x, rect.origin.y,rect.size.width, rect.size.height);

    
    CGContextSetRGBFillColor(context2, 1, 1, 1, 1);
    CGContextFillRect(context2, drawRect);
    CGContextStrokePath(context2);
  
    
    //Linea de Referencia
    
    CGContextRef context1 = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context1, 0.1);
    CGColorSpaceRef colorspace1 = CGColorSpaceCreateDeviceRGB();
    CGFloat components1[] = {0.0, 0.0, 0.0, 1};
    CGColorRef color1 = CGColorCreate(colorspace1, components1);
    CGContextSetStrokeColorWithColor(context1, color1);
    CGFloat dash []= {2,2};
    CGContextSetLineDash(context1, 0 , dash, 1);
    CGContextMoveToPoint(context1, 0, self.frame.size.height/2);
    CGContextAddLineToPoint(context1, self.frame.size.width, self.frame.size.height/2);
    CGContextStrokePath(context1);
    
    [self releasespace:colorspace1 color1:color1];

    

    //Rodaja de Circulo

    float alpha = .2;
    CGContextRef context = UIGraphicsGetCurrentContext();
    float Color1 = (pspi/2);
    float Color2 = (((pspi-0.5)*2-1))*(-1);
    float Color3 = ((pspi-1)*0.25);
    float Color4 = ((pspi-3)*0.25+0.5);
    if (pspi<=0.8) {
        CGContextSetRGBFillColor(context,1, Color1, 0, alpha);
    }
    else{
        if (pspi<=1) {
            CGContextSetRGBFillColor(context, Color2, 1 , 0, alpha);
        }
        else{
            if (pspi<=(1.25)) {
                CGContextSetRGBFillColor(context,0, 1 , Color3, alpha);
            }
            else{
                CGContextSetRGBFillColor(context,0 , 1 , Color4, alpha);
            }
        }
    }
    
    CGContextMoveToPoint(context, self.frame.size.width/2+20,self.frame.size.height/2);
    //float angulo = pspi/100* 2 * M_PI;
    //NSLog(@"%f,%f,%f,%f",pspi,angulo,Color1, Color2);
    CGContextAddArc(context,self.frame.size.width/2,self.frame.size.height/2, self.frame.size.width/2-5, (0.7*M_PI),(1.38*M_PI), 0);
    CGSize SZ = CGSizeMake(2, 1);
    CGContextSetShadow(context, SZ, 3);
    CGContextFillPath(context);

    
    
    //Indicador
    
    CGContextRef context3 = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context3, 2);
    CGColorSpaceRef colorspace3 = CGColorSpaceCreateDeviceRGB();
    CGFloat components3[] = {0.0, 0.0, 0.0, 5};
    CGColorRef color3 = CGColorCreate(colorspace3, components3);
    CGContextSetStrokeColorWithColor(context3, color3);
    CGContextMoveToPoint(context3, self.frame.size.width/2+20,self.frame.size.height/2);
    CGFloat dash3 []= {1,1};
    CGContextSetLineDash(context3, 0 , dash3, 1);
    double angle;
    if (pspi<=1){
        angle = pspi*(0.3*M_PI) + 0.7*M_PI;
    }
    else {
            if (pspi<=5){
                angle = pspi*0.3*M_PI/4 + M_PI;
                
            }
            else {
                angle = 5*(0.3*M_PI)/4 + M_PI;
        }
    }
    
    float angulo3 = angle;
    CGContextAddArc(context3,self.frame.size.width/2,self.frame.size.height/2, self.frame.size.width/2-5, angulo3 ,angulo3, 0);
    CGContextStrokePath(context3);
    

    //Pibote

    CGContextRef context5 = UIGraphicsGetCurrentContext();
    CGContextSetRGBFillColor(context5,0, 0, 0, 1);
    CGContextMoveToPoint(context5, self.frame.size.width/2+20,self.frame.size.height/2);
    CGContextAddArc(context5,self.frame.size.width/2+20,self.frame.size.height/2, 1.5, 0,M_PI*2, 0);
    CGContextFillPath(context5);
    
    

    
    
}

-(void)releasespace:(CGColorSpaceRef)colorspace1 color1:(CGColorRef)color1 {
    
    CGColorSpaceRelease(colorspace1);
    CGColorRelease(color1);
}

@end
