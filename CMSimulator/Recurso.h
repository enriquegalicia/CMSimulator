//
//  Recurso.h
//  CMSimulator
//
//  Created by Enrique Galicia on 27/10/15.
//  Copyright © 2015 Enrique Galicia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LDProgressView.h"
@protocol recursoA;

@interface Recurso : UIViewController{
    id<recursoA>delegadoA;
    IBOutlet UIImageView *IvImagen;
    IBOutlet UILabel *LTitulo;
    IBOutlet UILabel *LCosto;
    IBOutlet UILabel *LUnidades;
    IBOutlet UILabel *LRendimiento;
    IBOutlet UILabel *LTotal;
    IBOutlet UILabel *LStarts;
    IBOutlet LDProgressView *LDProgress;
    IBOutlet UIImageView *plus;
    IBOutlet UIImageView *minus;
    float contador;
    float unidadest;
    float costos;
    bool activo;
    bool activado;
    NSMutableDictionary *valores;
    NSTimer *Temporal;
}
@property (nonatomic,assign)id<recursoA>delegadoA;

@property (nonatomic)IBOutlet UIImageView *IvImagen;
@property (nonatomic)IBOutlet UILabel *LTitulo;
@property (nonatomic)IBOutlet UILabel *LNumero;
@property (nonatomic)IBOutlet UILabel *LCosto;
@property (nonatomic)IBOutlet UILabel *LUnidades;
@property (nonatomic)IBOutlet UILabel *LRendimiento;
@property (nonatomic)IBOutlet UILabel *LTotal;
@property (nonatomic)IBOutlet UILabel *LStarts;
@property (nonatomic)IBOutlet NSMutableDictionary *valores;
@property (nonatomic)IBOutlet LDProgressView *LDProgress;

    
-(void)setvalues:(NSString*)imagen titulo:(NSString*)titulo costo:(NSString*)costo unidades:(NSString*)unidades rendimiento:(NSString*)rendimiento total:(NSString*)total progreso:(double)progreso start:(NSString*)start;
-(void)play;
-(void)pause;
-(void)fastforward;
-(void)receiveprogress:(float)progress;

@end

@protocol recursoA

-(void)RPLUS;
-(void)RMINUS;

@end
