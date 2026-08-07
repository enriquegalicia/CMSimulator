//
//  ScoresDBNiveles.m
//  TequilaVodkaSessions
//
//  Created by Anis Galicia on 7/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DataBase.h"
#import "sqlite3.h"


@implementation DataBase

@synthesize MainDB;
@synthesize MainDBPath;


-(id)initDB:(NSString*)file Tablas:(NSArray*)Tablas{
    NSString *docsDir;
    NSArray *dirPaths;
    // Get the documents directory 
    dirPaths = NSSearchPathForDirectoriesInDomains (NSDocumentDirectory, NSUserDomainMask, YES);
    docsDir = [dirPaths objectAtIndex:0]; 
    // Build the path to the database file
    
    MainDBPath = [[NSString alloc] initWithString: [docsDir stringByAppendingPathComponent: file] ];
    //NSLog(@"%@",file);
    
    [self iniciarDB:(NSArray*)Tablas];

    
    //NSLog(@"Ya Existia la Base");
    return self;
}

-(void)iniciarDB:(NSArray*)Tablas{
    //NSLog(@"iniciar a colocar tablas %@",Tablas);
    NSFileManager *filemgr = [NSFileManager defaultManager];
    if ([filemgr fileExistsAtPath: MainDBPath ] == NO)
    {
        //NSLog(@"No Existia la Base");
        const char *dbpath = [MainDBPath UTF8String];
        if (sqlite3_open(dbpath, & MainDB) == SQLITE_OK){
            char *errMsg;
            NSUInteger count=[Tablas count];
            //NSLog(@"Tablas incluidas %lu",(unsigned long)count);
            if (count>0) {
                for (int a=0;a<=count-1; a++) {
                    NSArray *tabla=[Tablas objectAtIndex:a];
                    //NSLog(@"%@",tabla);
                    NSUInteger celdas=[tabla count];
                    if (celdas>0) {
                        NSString *oracion=@"CREATE TABLE IF NOT EXISTS";
                        for (int b=0; b<=celdas-1; b++) {
                            if (b==0) {
                                oracion=[NSString stringWithFormat:@"%@ %@ (ID INTEGER PRIMARY KEY AUTOINCREMENT,",oracion,[tabla objectAtIndex:b]];
                            }
                            if (b>0 && b<celdas-1) {
                                oracion=[NSString stringWithFormat:@"%@ %@,",oracion,[tabla objectAtIndex:b]];
                            }
                            if (b==celdas-1) {
                                oracion=[NSString stringWithFormat:@"%@ %@)",oracion,[tabla objectAtIndex:b]];
                            }
                        }
                        //NSLog(@"%@",oracion);
                        const char *sql_stmt = [oracion cStringUsingEncoding:NSASCIIStringEncoding];
                        if (sqlite3_exec(MainDB, sql_stmt, NULL, NULL, &errMsg) != SQLITE_OK) {
                            //NSLog(@"La he Creado");
                        }
                    }
                }
                
                
                
            }sqlite3_close(MainDB);
        }
        
        else {
            //NSLog(@"Falle con la Base Amo");
        }
    }
   // //NSLog(@"Ya Existia la Base");
}



-(void)revisarBD:(NSArray*)Campos Valores:(NSArray*)Valores Testigo:(NSString*)Testigo Tabla:(NSString*)Tabla Campo:(NSString*)Campo Nombre:(NSString*)Nombre{
    //NSLog(@"Campos %@",Campos);
    //NSLog(@"Valores %@",Valores);
    
    //NSLog(@"Voy a Revisar que Exista");
    const char *dbpath = [MainDBPath UTF8String];
    BOOL agrabar=FALSE;
    NSString *accion=nil;
    sqlite3_stmt *statement;
    if (sqlite3_open(dbpath, &MainDB) == SQLITE_OK) {
        //NSLog(@"Checo el enunciado");
        NSString *querySQL = [NSString stringWithFormat: @"SELECT %@ FROM %@ WHERE %@=\"%@\"" ,Testigo,Tabla,Campo,Nombre];
        //NSLog(@"Revision de Query%@",querySQL);
        const char *query_stmt = [querySQL UTF8String];
        if (sqlite3_prepare_v2(MainDB, query_stmt, -1, &statement, NULL) == SQLITE_OK) {
            //NSLog(@"Reviso la Consulta");
            if (sqlite3_step(statement) == SQLITE_ROW) {
            //NSLog(@"Ya Existe Usuario");
            } else {
                agrabar=TRUE;
                accion=@"Insertar";                
                
            } sqlite3_finalize(statement);
        } sqlite3_close(MainDB);
    }
    if (agrabar) {
         //NSLog(@"No Existia");
        if ([accion isEqualToString:@"Insertar"]) {
           //NSLog(@"A Insertar");
            [self guardarBD:Campos Valores:Valores Tabla:Tabla];
            
        }
        else {
                        
        }
    }
}


-(void)revisarBD2T:(NSArray*)Campos Valores:(NSArray*)Valores Testigo:(NSString*)Testigo Tabla:(NSString*)Tabla Campo:(NSString*)Campo Nombre:(NSString*)Nombre Campo2:(NSString*)Campo2 Nombre2:(NSString*)Nombre2{
    //NSLog(@"Campos %@",Campos);
    //NSLog(@"Valores %@",Valores);
    
    //NSLog(@"Voy a Revisar que Exista");
    const char *dbpath = [MainDBPath UTF8String];
    BOOL agrabar=FALSE;
    NSString *accion=nil;
    sqlite3_stmt *statement;
    if (sqlite3_open(dbpath, &MainDB) == SQLITE_OK) {
        //NSLog(@"Checo el enunciado");
        NSString *querySQL = [NSString stringWithFormat: @"SELECT %@ FROM %@ WHERE %@=\"%@\" AND %@=\"%@\"" ,Testigo,Tabla,Campo,Nombre,Campo2,Nombre2];
        //NSLog(@"Revision de Query %@",querySQL);
        
        const char *query_stmt = [querySQL UTF8String];
        if (sqlite3_prepare_v2(MainDB, query_stmt, -1, &statement, NULL) == SQLITE_OK) {
            
            //NSLog(@"Reviso la Consulta");
            if (sqlite3_step(statement) == SQLITE_ROW) {
                //NSLog(@"Ya Existe Usuario");
            } else {
                agrabar=TRUE;
                accion=@"Insertar";
                
            } sqlite3_finalize(statement);
        } sqlite3_close(MainDB);
    }
    if (agrabar) {
        //NSLog(@"No Existia");
        if ([accion isEqualToString:@"Insertar"]) {
            //NSLog(@"A Insertar");
            [self guardarBD:Campos Valores:Valores Tabla:Tabla];
        }
        else {

            
        }
    }
}


-(void)guardarBD:(NSArray*)Campos Valores:(NSArray*)Valores Tabla:(NSString*)Tabla {
    
    //NSLog(@"Insertare %@",Tabla);
    //NSLog(@"Campos GUARDAR %@",Campos);
    //NSLog(@"Valores GUARDAR %@",Valores);
    
    const char *dbpath1 = [MainDBPath UTF8String];
    if (sqlite3_open(dbpath1, &MainDB) == SQLITE_OK) {
        sqlite3_stmt *statement;
        NSUInteger count=[Campos count];
        NSString *oracion=[NSString stringWithFormat:@"INSERT INTO %@(",Tabla];
        if (count>0) {
            for (int a=0;a<=count-1; a++) {
                if (a<count-1) {
                    oracion=[NSString stringWithFormat:@"%@%@,",oracion,[Campos objectAtIndex:a]];
                }
                else{
                   oracion=[NSString stringWithFormat:@"%@%@) VALUES ",oracion,[Campos objectAtIndex:a]];
                }
            }
            for (int a=0; a<=count-1; a++) {
                if (a==0) {
                    oracion=[NSString stringWithFormat:@"%@(\"%@\",",oracion,[Valores objectAtIndex:a]];
                }
                else if (a<count-1) {
                    oracion=[NSString stringWithFormat:@"%@\"%@\",",oracion,[Valores objectAtIndex:a]];
                }
                else{
                    oracion=[NSString stringWithFormat:@"%@\"%@\")",oracion,[Valores objectAtIndex:a]];
                }
                
            }
        }
        //NSLog(@"Ore y Ore esto %@",oracion);
        const char *insert_stmt = [oracion UTF8String];
        sqlite3_prepare_v2(MainDB, insert_stmt, -1, &statement, NULL);
        if (sqlite3_step(statement) == SQLITE_DONE) {
        //NSLog(@"Puedo Insertar.");
        }
        else {
            int rc = sqlite3_step(statement);
            if (rc == SQLITE_OK)
            {
                //NSLog(@"Añadido.");
            } else {
                //NSLog(@"ERROR:  Failed to add food!: %d", rc);
            }
            
        }
        sqlite3_finalize(statement);
        
        
    }
    
    sqlite3_close(MainDB);
    
}

- (void)update:(NSString*)Nombre{
    //NSLog(@"Actualizare");
    sqlite3_stmt *statement;
    const char *dbpath1 = [MainDBPath UTF8String];
    if (sqlite3_open(dbpath1, & MainDB) == SQLITE_OK) {
        NSString *updateSQL = Nombre;
        const char *update_stmt = [updateSQL UTF8String];
       // NSLog(@"Insertare consulta UPDATE");
        
        sqlite3_prepare_v2(MainDB, update_stmt, -1, &statement, NULL);
        if (sqlite3_step(statement) == SQLITE_DONE) {
            //NSLog(@"Pudo ACTUALIZAR");
        }
        else {
            int rc = sqlite3_step(statement);
            if (rc == SQLITE_OK)
            {
                //NSLog(@"Grupo ACTUALIZADO");
            } else {
            }
        }
        sqlite3_finalize(statement);
        sqlite3_close(MainDB);
    }
}

    
-(NSDictionary*)getalltablesfromDB:(NSString*)tabla campos:(NSArray*)campos{

    NSMutableDictionary *tlu=[[NSMutableDictionary alloc]init];
    NSMutableArray *titcampos=[[NSMutableArray alloc]init];
    NSMutableArray *titarrays=[[NSMutableArray alloc]init];
    
    if ([campos count]>0) {
        for (int a=0; a<=[campos count]-1; a++) {
            NSMutableArray *campo=[[NSMutableArray alloc]init];
            [titcampos addObject:campo];
        }
    }
    const char *dbpath = [MainDBPath UTF8String];
    //NSLog(@"%@",NivelesDBPath);
    sqlite3_stmt *statement;
    if (sqlite3_open(dbpath, &MainDB) == SQLITE_OK) {
        
        NSString *querySQL = [NSString stringWithFormat: @"SELECT * FROM %@",tabla];
        const char *query_stmt = [querySQL UTF8String];
        //NSLog(@"%@",querySQL);
        if (sqlite3_prepare_v2(MainDB, query_stmt, -1, &statement, NULL) == SQLITE_OK) {
            //NSLog(@"Ejecute");
            while(sqlite3_step(statement) == SQLITE_ROW) {
                for (int b=0; b<=[campos count]-1; b++) {
                    NSString *ninfo= [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, b)];
                    [[titcampos objectAtIndex:b]addObject:ninfo];
                }
            }
            sqlite3_finalize(statement);
        } sqlite3_close(MainDB);
    }
    if ([campos count]>0) {
        for (int a=0; a<=[campos count]-1; a++) {
            NSArray *aID=[NSArray arrayWithArray:[titcampos objectAtIndex:a]];
            [titarrays addObject:aID];
        }
    }
    if ([campos count]>0) {
        for (int a=0; a<=[campos count]-1; a++) {
            [tlu setObject:[titarrays objectAtIndex:a] forKey:[campos objectAtIndex:a]];
        }
    }
    NSDictionary *final=[NSDictionary dictionaryWithDictionary:tlu];
    //NSLog(@"%@FINAL",final);
    
    return final;
}

-(NSDictionary*)getalldatafromstatement:(NSString*)oracion campos:(NSArray*)campos{
    
    NSMutableDictionary *tlu=[[NSMutableDictionary alloc]init];
    NSMutableArray *titcampos=[[NSMutableArray alloc]init];
    NSMutableArray *titarrays=[[NSMutableArray alloc]init];
    
    if ([campos count]>0) {
        for (int a=0; a<=[campos count]-1; a++) {
            NSMutableArray *campo=[[NSMutableArray alloc]init];
            [titcampos addObject:campo];
        }
    }
    const char *dbpath = [MainDBPath UTF8String];

    sqlite3_stmt *statement;
    if (sqlite3_open(dbpath, &MainDB) == SQLITE_OK) {
        
        NSString *querySQL = oracion;
        const char *query_stmt = [querySQL UTF8String];

        if (sqlite3_prepare_v2(MainDB, query_stmt, -1, &statement, NULL) == SQLITE_OK) {

            while(sqlite3_step(statement) == SQLITE_ROW) {
                for (int b=0; b<=[campos count]-1; b++) {
                    NSString *ninfo= ((char *)sqlite3_column_text(statement, b)) ? [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, b)] : nil;
                    if (ninfo) {
                         [[titcampos objectAtIndex:b]addObject:ninfo];
                    }
                    else{
                        [[titcampos objectAtIndex:b]addObject:@"0"];
                    }
                   
                }
            }
            sqlite3_finalize(statement);
        } sqlite3_close(MainDB);
    }
    if ([campos count]>0) {
        for (int a=0; a<=[campos count]-1; a++) {
            NSArray *aID=[NSArray arrayWithArray:[titcampos objectAtIndex:a]];
            [titarrays addObject:aID];
        }
    }
    if ([campos count]>0) {
        for (int a=0; a<=[campos count]-1; a++) {
            [tlu setObject:[titarrays objectAtIndex:a] forKey:[campos objectAtIndex:a]];
        }
    }
    NSDictionary *final=[NSDictionary dictionaryWithDictionary:tlu];
    //NSLog(@"%@FINAL",final);
    
    return final;
}

-(NSString*)getselecteddatafromstatement:(NSString*)oracion{
    NSString *selected=@"";
     //NSLog(@"A ejecutar oracion");
    const char *dbpath = [MainDBPath UTF8String];
    
    sqlite3_stmt *statement;
    if (sqlite3_open(dbpath, &MainDB) == SQLITE_OK) {
        
        NSString *querySQL = oracion;
        //NSLog(@"oracion%@",oracion);
        const char *query_stmt = [querySQL UTF8String];
        
        if (sqlite3_prepare_v2(MainDB, query_stmt, -1, &statement, NULL) == SQLITE_OK) {
            
            while(sqlite3_step(statement) == SQLITE_ROW) {

                selected=((char *)sqlite3_column_text(statement, 0)) ? [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 0)] : nil;
                
                //[[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 0)];
                
                /*[NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledStatement, 15)]
                ((char *)sqlite3_column_text(compiledStatement, 15)) ? [NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledStatement, 15)] : nil;*/
                //NSLog(@"informacion obtenida %@",selected);
            }
            sqlite3_finalize(statement);
        } sqlite3_close(MainDB);
    }
    return selected;
}


-(void)deletetable:(NSString*)table Tablas:(NSArray*)Tablas{
    
    //NSLog(@"Insertare");
    sqlite3_stmt *statement;
    sqlite3_stmt *statement2;
    const char *dbpath1 = [MainDBPath UTF8String];
    if (sqlite3_open(dbpath1, &MainDB) == SQLITE_OK) {
        NSString *updateSQL = [NSString stringWithFormat: @"DROP TABLE %@",table];
        const char *update_stmt = [updateSQL UTF8String];
        sqlite3_prepare_v2(MainDB, update_stmt, -1, &statement, NULL);
        if (sqlite3_step(statement) == SQLITE_DONE) {
            //NSLog(@"Puedo Insertar.");
        }
        else {
            int rc = sqlite3_step(statement);
            if (rc == SQLITE_OK)
            {
                //NSLog(@"Exito");
            } else {
                //NSLog(@"ERROR:  Failed to update!: %d", rc);
            }
        }
        NSString *createSQL=@"";
        NSUInteger count=[Tablas count];
        if (count>0) {
            for (int a=0;a<=count-1; a++) {
                NSArray *tabla=[Tablas objectAtIndex:a];
                NSUInteger celdas=[tabla count];
                if (celdas>0) {
                    NSString *oracion=@"CREATE TABLE IF NOT EXISTS";
                    for (int b=0; b<=celdas-1; b++) {
                        if (b==0) {
                            oracion=[NSString stringWithFormat:@"%@ %@ (ID INTEGER PRIMARY KEY AUTOINCREMENT,",oracion,[tabla objectAtIndex:b]];
                        }
                        if (b>0 && b<celdas-1) {
                            oracion=[NSString stringWithFormat:@"%@ %@,",oracion,[tabla objectAtIndex:b]];
                        }
                        if (b==celdas-1) {
                            oracion=[NSString stringWithFormat:@"%@ %@)",oracion,[tabla objectAtIndex:b]];
                        }
                    }
                    createSQL=oracion;
                }
            }
        }

        const char *create_stmt = [createSQL UTF8String];
        sqlite3_prepare_v2(MainDB, create_stmt, -1, &statement2, NULL);
        if (sqlite3_step(statement2) == SQLITE_DONE) {

        }
        else {
            int rc = sqlite3_step(statement);
            if (rc == SQLITE_OK)
            {

            } else {

            }
        }
        sqlite3_finalize(statement);
        sqlite3_close(MainDB);
    }
}






@end
