//
//  GestorBD.h
//  GestorBIM
//
//  Created by Enrique Galicia on 20/03/14.
//
//

#import <Foundation/Foundation.h>
#import "DataBase.h"


@interface GestorBD : NSObject{
    DataBase *Basedatos;
    NSMutableDictionary *valores;
}
-(id)initwithdatabases;
-(void)saveinfo:(NSArray*)info val:(NSString*)val testigo:(NSString*)testigo tabla:(NSString*)tabla campo:(NSString*)campo nombre:(NSString*)nombre;
-(void)updateinfo:(NSString*)info;
-(NSDictionary*)getalltb:(NSString*)tabla val:(NSString*)val;
-(NSDictionary*)getselecteddatatb:(NSString*)tabla val:(NSArray*)val;
-(NSDictionary*)getselecteddatastatement:(NSString*)statement val:(NSArray*)val;
-(NSString*)getsingle:(NSString*)statement;
-(void)renewal:(NSString*)tabla tablas:(NSString*)tablas;

@end
