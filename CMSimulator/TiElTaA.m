 //
//  BasicTable.m
//  Magma
//
//  Created by Enrique Galicia on 19/08/13.
//  Copyright (c) 2013 Enrique Galicia. All rights reserved.
//

#import "TiElTaA.h"

@interface TiElTaA ()

@end

@implementation TiElTaA
@synthesize delegadores5=_delegadores5,tamsubtit,tamtit,funcion;
@synthesize celda;
@synthesize resul=_resul;



- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    cantidaddeelementos=0;
    valoresphp=[[NSMutableDictionary alloc]init];
    self.view.backgroundColor=[UIColor clearColor];
    [self.tableView registerNib:[UINib nibWithNibName:@"Resultados_Finales"
                                               bundle:[NSBundle mainBundle]]
         forCellReuseIdentifier:@"cell"];

}
-(void)ocurrir{
    NSLog(@"Señora si Cargue");
    [self cargartablas:[self.delegadores5 obtenerinformacion]];
}
-(void)cargartablas:(NSDictionary*)informacion{


    idd=[informacion objectForKey:@"Id"];
    idd2=[idd copy];
    Nombre=[informacion objectForKey:@"Nombre"];
    Nombre2=[Nombre copy];
    Costo=[informacion objectForKey:@"Costo"];
    Costo2=[Costo copy];
    Tiempo=[informacion objectForKey:@"Tiempo"];
    Tiempo2=[Tiempo copy];
    Dia=[informacion objectForKey:@"Dia"];
    Dia2=[Dia copy];
    Mes=[informacion objectForKey:@"Mes"];
    Mes2=[Mes copy];
    Ano=[informacion objectForKey:@"Ano"];
    Ano2=[Ano copy];
    cantidaddeelementos=[idd count];
    [self.tableView reloadData];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Table view data source


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (cantidaddeelementos>0) {
        return cantidaddeelementos;
    }
    else{
    return 1;
    }

}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    TiElA *resulta = (TiElA *)[tableView dequeueReusableCellWithIdentifier:[TiElA reuseIdentifier]];
    if (resulta == nil) {
        [[NSBundle mainBundle] loadNibNamed:@"TiElA" owner:self options:nil];
        resulta = _resul;
        _resul = nil;
    }
    
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    if ([idd count]>0) {
        resulta.backgroundColor=[UIColor clearColor];
        resulta.Num.text=[NSString stringWithFormat:@"%li",indexPath.row+1];
        NSLog(@"Cargue Tabla");
        
        float costo=[[Costo2 objectAtIndex:indexPath.row] floatValue];
        NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
        [numberFormatter setNumberStyle: NSNumberFormatterCurrencyStyle];
        NSString *numberAsString = [numberFormatter stringFromNumber:[NSNumber numberWithFloat:costo]];

        float dias=[[Tiempo2 objectAtIndex:indexPath.row] floatValue];
        int diastot=dias;
        float horas=(dias-diastot)*8;
        int horast=horas;
        NSString *tiempo=[NSString stringWithFormat:@"%i Days %i Hours",diastot,horast];
        resulta.Titulo.text=[NSString stringWithFormat:@"%@ %@",numberAsString,tiempo];
        resulta.Subtitulo.text=[NSString stringWithFormat:@"%@ %@/%@/%@",[Nombre2 objectAtIndex:indexPath.row],[Dia2 objectAtIndex:indexPath.row],[Mes2 objectAtIndex:indexPath.row],[Ano2 objectAtIndex:indexPath.row]];
        
    }


    return resulta;
}
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
    return 50;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
   if ([idd2 count]>0) {
    [self.delegadores5 setselected:@"" fun:@""];
       
    }
}


@end
