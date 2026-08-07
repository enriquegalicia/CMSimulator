//
//  BasicTable.h
//  Magma
//
//  Created by Enrique Galicia on 19/08/13.
//  Copyright (c) 2013 Enrique Galicia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TiElA.h"

@protocol restable5;

@interface TiElTaA : UITableViewController{
    
    id<restable5>delegadores5;
    NSArray *idd;
    NSArray *idd2;
    NSArray *Nombre;
    NSArray *Costo;
    NSArray *Tiempo;
    NSArray *Dia;
    NSArray *Mes;
    NSArray *Ano;
    NSArray *Nombre2;
    NSArray *Costo2;
    NSArray *Tiempo2;
    NSArray *Dia2;
    NSArray *Mes2;
    NSArray *Ano2;
    
    
    NSUInteger cantidaddeelementos;
    NSMutableDictionary *valoresphp;
    int tamtit;
    int tamsubtit;
    int funcion;
    int celda;
    IBOutlet TiElA *resul;


}


@property(nonatomic,assign)int tamtit;
@property(nonatomic,assign)int funcion;
@property(nonatomic,assign)int tamsubtit;
@property(nonatomic,assign)int celda;
@property(nonatomic,retain)id<restable5>delegadores5;

@property(nonatomic,retain)NSDictionary *informacion;
@property(nonatomic,assign)float *maxduracion;
@property (assign, nonatomic)IBOutlet TiElA *resul;

-(void)cargartablas:(NSDictionary*)informacion;
-(void)ocurrir;

@end

@protocol restable5

-(void)setselected:(NSString*)seleccion fun:(NSString*)fun;
-(NSDictionary*)obtenerinformacion;

@end



