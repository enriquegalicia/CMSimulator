//
//  Potenciadores.h
//  CMSimulator
//
//  Created by Enrique Galicia on 27/10/15.
//  Copyright © 2015 Enrique Galicia. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol potA;

@interface Potenciadores : UIViewController{
    id<potA>delA;
    IBOutlet UIImageView *IvImagen;
    IBOutlet UILabel *LTitulo;
    IBOutlet UILabel *LCosto;
    IBOutlet UILabel *LTotal;
    IBOutlet UILabel *LNumero;
    IBOutlet UILabel *LStarts;
    IBOutlet UILabel *LAffects;
    IBOutlet UIImageView *plus;
    IBOutlet UIImageView *minus;
    float contador;
    float costos;
    bool activo;
    bool activado;
    NSMutableDictionary *valores;
    NSTimer *Temporal;

    
}

@property (nonatomic,assign)id<potA>delA;

@property (nonatomic)IBOutlet UIImageView *IvImagen;
@property (nonatomic)IBOutlet UILabel *LTitulo;
@property (nonatomic) NSMutableDictionary *valores;
@property (nonatomic)IBOutlet UILabel *LNumero;
@property (nonatomic)IBOutlet UILabel *LCosto;
@property (nonatomic)IBOutlet UILabel *LTotal;
@property (nonatomic)IBOutlet UILabel *LStarts;
@property (nonatomic,assign)bool activado;


-(void)setvalues:(NSString*)imagen titulo:(NSString*)titulo costo:(NSString*)costo total:(NSString*)total start:(NSString*)start  affects:(NSString*)affects;
-(void)play;
-(void)pause;
-(void)fastforward;
-(void)receiveprogress:(float)progress;
-(void)resetpower;

@end

@protocol potA

-(void)RPLUSA:(NSString*)funcion;
-(void)RMINUSA:(NSString*)funcion;


@end
