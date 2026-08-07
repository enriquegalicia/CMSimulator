//
//  GestorBD.m
//  GestorBIM
//
//  Created by Enrique Galicia on 20/03/14.
//
//

#import "GestorBD.h"

@implementation GestorBD
-(id)initwithdatabases{
    
    valores=[[NSMutableDictionary alloc]init];
    
    //Nivel1
    NSArray *artaba=[NSArray arrayWithObjects:@"SCORES",@"NOMBRE TEXT",@"COSTO FLOAT",@"TIEMPO FLOAT",@"DIA TEXT",@"MES TEXT",@"ANO TEXT", nil];
    
    NSArray *BDN1=[NSArray arrayWithObjects:@"Id",@"Nombre",@"Costo",@"Tiempo",@"Dia",@"Mes",@"Ano",  nil];
    NSArray *BDN1S=[NSArray arrayWithObjects:@"Nombre",@"Costo",@"Tiempo",@"Dia",@"Mes",@"Ano", nil];
    
    [valores setObject:BDN1 forKey:@"BDN1"];
    [valores setObject:BDN1S forKey:@"BDN1S"];
    

    NSArray *completo =[NSArray arrayWithObjects:artaba,nil];

    Basedatos=[[DataBase alloc]initDB:@"ini1.db" Tablas:completo];
    
    return self;
    
}

-(void)saveinfo:(NSArray*)info val:(NSString*)val testigo:(NSString*)testigo tabla:(NSString*)tabla campo:(NSString*)campo nombre:(NSString*)nombre{
    //NSLog(@"Info%@",info);
    [Basedatos revisarBD:[valores objectForKey:val] Valores:info Testigo:testigo Tabla:tabla Campo:campo Nombre:nombre];


}
-(void)saveinfoalways:(NSArray*)info val:(NSString*)val tabla:(NSString*)tabla{
    // Unlike saveinfo:, this always inserts a new row instead of skipping
    // when a matching name already exists - needed for a leaderboard where
    // the same player logs multiple runs.
    [Basedatos guardarBD:[valores objectForKey:val] Valores:info Tabla:tabla];
}
-(void)updateinfo:(NSString*)info{
    [Basedatos update:info];
}
-(NSDictionary*)getalltb:(NSString*)tabla val:(NSString*)val{
    return [Basedatos getalltablesfromDB:tabla campos:[valores objectForKey:val]];
}

-(NSDictionary*)getselecteddatatb:(NSString*)tabla val:(NSArray*)val{
    return [Basedatos getalltablesfromDB:tabla campos:val];
}

-(NSDictionary*)getselecteddatastatement:(NSString*)statement val:(NSArray*)val{
    return [Basedatos getalldatafromstatement:statement campos:val];
}

-(NSString*)getsingle:(NSString*)statement{
    return [Basedatos getselecteddatafromstatement:statement];
}
-(void)renewal:(NSString*)tabla tablas:(NSString*)tablas{
    [Basedatos deletetable:tabla Tablas:[valores objectForKey:tablas]];
}



@end
