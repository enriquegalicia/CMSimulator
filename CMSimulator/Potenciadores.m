//
//  Potenciadores.m
//  CMSimulator
//
//  Created by Enrique Galicia on 27/10/15.
//  Copyright © 2015 Enrique Galicia. All rights reserved.
//

#import "Potenciadores.h"

@interface Potenciadores ()

@end

@implementation Potenciadores
@synthesize valores,IvImagen,LStarts,LTitulo,LCosto,LTotal,LNumero,activado,delA=_delA;

- (void)viewDidLoad {
    [super viewDidLoad];
    IvImagen.alpha=0.3;
    plus.alpha=0.3;
    minus.alpha=0.3;
    LTitulo.alpha=0.3;
    LCosto.text=@"???";
    LTotal.text=@"???";
    [plus setUserInteractionEnabled:NO];
    [minus setUserInteractionEnabled:NO];
    activo=TRUE;
    // Do any additional setup after loading the view from its nib.
}
-(void)resetpower{
    IvImagen.alpha=0.3;
    plus.alpha=0.3;
    minus.alpha=0.3;
    LTitulo.alpha=0.3;
    LCosto.text=@"???";
    LTotal.text=@"???";
    LNumero.text=@"0";
    [plus setUserInteractionEnabled:NO];
    [minus setUserInteractionEnabled:NO];
    activo=TRUE;
    activado=FALSE;
    contador=0;
    costos=0;
}
-(void)setvalues:(NSString*)imagen titulo:(NSString*)titulo costo:(NSString*)costo total:(NSString*)total start:(NSString*)start affects:(NSString*)affects{
    IvImagen.image=[UIImage imageNamed:imagen];
    [LTitulo setText:titulo];

    valores=[[NSMutableDictionary alloc]init];
    [valores setObject:costo forKey:@"Costo"];
    [valores setObject:costo forKey:@"CostoI"];
    [valores setObject:@"$0.00" forKey:@"CostoAcumulado"];
    [valores setObject:@"0" forKey:@"Numero"];
    [valores setObject:start forKey:@"Start"];
    [valores setObject:@"0.0" forKey:@"Global"];
    contador=0;
    costos=0;
    LStarts.text=[NSString stringWithFormat:@"%@%%",start];
    LAffects.text=[NSString stringWithFormat:@"%@",affects];
    if ([[valores objectForKey:@"Start"] floatValue]<=[[valores objectForKey:@"Global"] floatValue]) {
        IvImagen.alpha=1;
        plus.alpha=1;
        minus.alpha=1;
        LTitulo.alpha=1;
        LCosto.text=costo;
        LTotal.text=total;
        [plus setUserInteractionEnabled:YES];
        [minus setUserInteractionEnabled:YES];
    }

}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    UITouch *touch =[touches anyObject];
    if ([touch view]==plus) {
        [self suma];
    }
    else if([touch view]==minus){
        [self resta];
    }
    
}
-(void)suma{
    //Numero
    int numero=[[valores objectForKey:@"Numero"]intValue]+1;
    if (numero<=6) {
        NSString *nuevonumero=[NSString stringWithFormat:@"%i",numero];
        LNumero.text=nuevonumero;
        [valores setObject:nuevonumero forKey:@"Numero"];
        //Costo Y Acumulado
        NSString *texto1=[valores objectForKey:@"Costo"];
        //NSLog(@"Costo %@",texto1);
        NSString *texto2=[valores objectForKey:@"CostoAcumulado"];
        //NSLog(@"Costo Acumulado%@",texto2);
        float Costo=[[texto1 substringFromIndex:1]floatValue];
        float NuevoCosto=Costo*[self randomFloatBetween:0.98 and:1.05];
        //NSLog(@"Nuevo Costo%f",NuevoCosto);
        float CostoAcumulado=[[texto2 substringFromIndex:1]floatValue]+Costo;
        NSString *SCosto=[NSString stringWithFormat:@"$%.02f",NuevoCosto];
        NSString *SCostoAcumulado=[NSString stringWithFormat:@"$%.02f",CostoAcumulado];
        [valores setObject:SCosto forKey:@"Costo"];
        [valores setObject:SCostoAcumulado forKey:@"CostoAcumulado"];
        LCosto.text=SCosto;
        //NSLog(@"1");
        [UIView animateWithDuration:1.0 animations:^{
            LCosto.layer.backgroundColor = [UIColor greenColor].CGColor;
        } completion:NULL];
        [UIView animateWithDuration:3.0 animations:^{
            LCosto.layer.backgroundColor = [UIColor whiteColor].CGColor;
        } completion:NULL];
        [self.delA RPLUSA:LTitulo.text];
    }


}
-(void)resta{
    int numero=[[valores objectForKey:@"Numero"]intValue]-1;
    if (numero>=0) {
        //Numero
        NSString *nuevonumero=[NSString stringWithFormat:@"%i",numero];
        LNumero.text=nuevonumero;
        [valores setObject:nuevonumero forKey:@"Numero"];
        //Costo Y Acumulado
        NSString *texto1=[valores objectForKey:@"Costo"];
        //NSLog(@"Costo %@",texto1);
        NSString *texto2=[valores objectForKey:@"CostoAcumulado"];
        //NSLog(@"Costo Acumulado%@",texto2);
        float Costo=[[texto1 substringFromIndex:1]floatValue];
        float NuevoCosto=Costo*[self randomFloatBetween:0.95 and:1.02];
        //NSLog(@"Nuevo Costo%f",NuevoCosto);
        float CostoAcumulado=[[texto2 substringFromIndex:1]floatValue]-Costo;
        NSString *SCosto=[NSString stringWithFormat:@"$%.02f",NuevoCosto];
        NSString *SCostoAcumulado=[NSString stringWithFormat:@"$%.02f",CostoAcumulado];
        [valores setObject:SCosto forKey:@"Costo"];
        [valores setObject:SCostoAcumulado forKey:@"CostoAcumulado"];
        LCosto.text=SCosto;
        [UIView animateWithDuration:1.0 animations:^{
            LCosto.layer.backgroundColor = [UIColor redColor].CGColor;
        } completion:NULL];
        [UIView animateWithDuration:3.0 animations:^{
            LCosto.layer.backgroundColor = [UIColor whiteColor].CGColor;
        } completion:NULL];

        [self.delA RMINUSA:LTitulo.text];
    }
    //NSLog(@"2");
}
-(void)play{
    if ([Temporal isValid]) {
        [Temporal invalidate];
        Temporal=nil;
    }
    Temporal=[NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(progress) userInfo:nil repeats:YES];
}

-(void)pause{
    if ([Temporal isValid]) {
        [Temporal invalidate];
        Temporal=nil;
    }
}
-(void)fastforward{
    if ([Temporal isValid]) {
        [Temporal invalidate];
        Temporal=nil;
    }
    Temporal=[NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(progress2) userInfo:nil repeats:YES];
    
}
-(void)progress{
    
        if ([LNumero.text floatValue]>0) {
            NSString *costoacumulado=[valores objectForKey:@"CostoAcumulado"];
            float fcostoacumulado=[[costoacumulado substringFromIndex:1] floatValue];
            float costost=fcostoacumulado*.01;
            costos=costos+costost;
            //NSLog(@"Costo%f",costos);
            NSString *SCostoTotal=[NSString stringWithFormat:@"$%.02f",costos];
            LTotal.text=SCostoTotal;
        }
}
-(void)progress2{
        if ([LNumero.text floatValue]>0) {
            NSString *costoacumulado=[valores objectForKey:@"CostoAcumulado"];
            float fcostoacumulado=[[costoacumulado substringFromIndex:1] floatValue];
            float costost=fcostoacumulado*.1;
            costos=costos+costost;
            NSString *SCostoTotal=[NSString stringWithFormat:@"$%.02f",costos];
            LTotal.text=SCostoTotal;
        }
        else {
            
            
            
        }
    
}
-(void)receiveprogress:(float)progress{
    if (activo) {
        if (progress>=[[valores objectForKey:@"Start"]floatValue]) {
            IvImagen.alpha=1;
            plus.alpha=1;
            minus.alpha=1;
            LTitulo.alpha=1;
            LCosto.text=[valores objectForKey:@"Costo"];
            LTotal.text=[valores objectForKey:@"Total"];
            [plus setUserInteractionEnabled:YES];
            [minus setUserInteractionEnabled:YES];
            activo=FALSE;
        }
    }
}

- (float)randomFloatBetween:(float)smallNumber and:(float)bigNumber {
    float diff = bigNumber - smallNumber;
    return (((float) (arc4random() % ((unsigned)RAND_MAX + 1)) / RAND_MAX) * diff) + smallNumber;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
