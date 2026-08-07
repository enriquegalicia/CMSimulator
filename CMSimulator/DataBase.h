//
//  ScoresDBNiveles.h
//  TequilaVodkaSessions
//
//  Created by Anis Galicia on 7/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "sqlite3.h"

@interface DataBase : NSObject{
}

@property(nonatomic) sqlite3 *MainDB;
@property(nonatomic,strong)NSString *MainDBPath;

-(id)initDB:(NSString*)file Tablas:(NSArray*)Tablas;
-(void)revisarBD:(NSArray*)Campos Valores:(NSArray*)Valores Testigo:(NSString*)Testigo Tabla:(NSString*)Tabla Campo:(NSString*)Campo Nombre:(NSString*)Nombre;
-(void)revisarBD2T:(NSArray*)Campos Valores:(NSArray*)Valores Testigo:(NSString*)Testigo Tabla:(NSString*)Tabla Campo:(NSString*)Campo Nombre:(NSString*)Nombre Campo2:(NSString*)Campo2 Nombre2:(NSString*)Nombre2;
-(void)guardarBD:(NSArray*)Campos Valores:(NSArray*)Valores Tabla:(NSString*)Tabla;
-(void)update:(NSString*)Nombre;
-(NSDictionary*)getalltablesfromDB:(NSString*)tabla campos:(NSArray*)campos;
-(NSDictionary*)getalldatafromstatement:(NSString*)oracion campos:(NSArray*)campos;
-(NSString*)getselecteddatafromstatement:(NSString*)oracion;
-(void)deletetable:(NSString*)table Tablas:(NSArray*)Tablas;

@end
