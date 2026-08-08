//
//  Recurso.m
//  CMSimulator
//
//  Created by Enrique Galicia on 27/10/15.
//  Copyright © 2015 Enrique Galicia. All rights reserved.
//

#import "Recurso.h"

@interface Recurso ()

@end

@implementation Recurso

@synthesize valores,IvImagen,LTitulo,LCosto,LUnidades,LRendimiento,LTotal,LDProgress,LNumero,LStarts,delegadoA=_delegadoA;



- (void)viewDidLoad {
    [super viewDidLoad];
    
    LDProgress.color = [UIColor colorWithRed:0.00f green:0.64f blue:0.00f alpha:1.00f];
    LDProgress.flat = @YES;
    LDProgress.borderRadius = @4;
    LDProgress.showBackgroundInnerShadow = @NO;
    LDProgress.progress = 0.40;
    LDProgress.animate = @YES;
    valores=[[NSMutableDictionary alloc]init];
    IvImagen.alpha=0.5;
    plus.alpha=0.5;
    minus.alpha=0.5;
    LTitulo.alpha=0.5;
    LDProgress.alpha=0.5;
    LCosto.text=@"???";
    LRendimiento.text=@"???";
    LUnidades.text=@"???";
    LTotal.text=@"???";
    [plus setUserInteractionEnabled:NO];
    [minus setUserInteractionEnabled:NO];
    activo=TRUE;
    
   

    // Do any additional setup after loading the view from its nib.
}



-(void)setvalues:(NSString*)imagen titulo:(NSString*)titulo costo:(NSString*)costo unidades:(NSString*)unidades rendimiento:(NSString*)rendimiento total:(NSString*)total progreso:(double)progreso start:(NSString*)start {
    //NSLog(@"Ejecute %@, %@ %@ %@ %@ %@ %f",imagen,titulo,costo,unidades,rendimiento,total,progreso);
    IvImagen.image=[UIImage imageNamed:imagen];
    [LTitulo setText:titulo];
    //NSLog(@"%@",LTitulo.text);
    
    LDProgress.progress=progreso;
    [valores setObject:costo forKey:@"CostoI"];
    [valores setObject:rendimiento forKey:@"RendimientoI"];
    [valores setObject:costo forKey:@"Costo"];
    [valores setObject:@"$0.00" forKey:@"CostoAcumulado"];
    [valores setObject:rendimiento forKey:@"Rendimiento"];
    [valores setObject:rendimiento forKey:@"RendimientoI"];
    [valores setObject:@"0" forKey:@"RendimientoAcumulado"];
    [valores setObject:@"0" forKey:@"Numero"];
    [valores setObject:unidades forKey:@"Unidades"];
    [valores setObject:start forKey:@"Start"];
    [valores setObject:@"0.0" forKey:@"Global"];
    contador=0;
    IvImagen.alpha=0.5;
    plus.alpha=0.5;
    minus.alpha=0.5;
    LTitulo.alpha=0.5;
    LDProgress.alpha=0.5;
    LStarts.text=[NSString stringWithFormat:@"%@%%",start];
    activado=FALSE;
    LCosto.text=@"???";
    LRendimiento.text=@"???";
    LUnidades.text=@"???";
    LTotal.text=@"???";

    if ([[valores objectForKey:@"Start"] floatValue]<=[[valores objectForKey:@"Global"] floatValue]) {
        IvImagen.alpha=1;
        plus.alpha=1;
        minus.alpha=1;
        LTitulo.alpha=1;
        LDProgress.alpha=1;
        LCosto.text=[valores objectForKey:@"Costo"];
        LUnidades.text=[valores objectForKey:@"Unidades"];
        LRendimiento.text=[valores objectForKey:@"Rendimiento"];
        LTotal.text=total;
        [plus setUserInteractionEnabled:YES];
        [minus setUserInteractionEnabled:YES];
        activado=TRUE;
        
    }
}

-(void)resetresource{
    LDProgress.color = [UIColor colorWithRed:0.00f green:0.64f blue:0.00f alpha:1.00f];
    LDProgress.flat = @YES;
    LDProgress.borderRadius = @4;
    LDProgress.showBackgroundInnerShadow = @NO;
    LDProgress.progress = 0.40;
    LDProgress.animate = @YES;
    valores=[[NSMutableDictionary alloc]init];
    IvImagen.alpha=0.5;
    plus.alpha=0.5;
    minus.alpha=0.5;
    LTitulo.alpha=0.5;
    LDProgress.alpha=0.5;
    LCosto.text=@"???";
    LRendimiento.text=@"???";
    LUnidades.text=@"???";
    LTotal.text=@"???";
    LNumero.text=@"0";
    [plus setUserInteractionEnabled:NO];
    [minus setUserInteractionEnabled:NO];
    activo=TRUE;
    costos=0;
    unidadest=0;
    contador=0;
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
- (float)randomFloatBetween:(float)smallNumber and:(float)bigNumber {
    float diff = bigNumber - smallNumber;
    return (((float) (arc4random() % ((unsigned)RAND_MAX + 1)) / RAND_MAX) * diff) + smallNumber;
}
-(void)receiveprogress:(float)progress{
    if (activo) {
        if (progress>=[[valores objectForKey:@"Start"]floatValue]) {
            IvImagen.alpha=1;
            plus.alpha=1;
            minus.alpha=1;
            LTitulo.alpha=1;
            LDProgress.alpha=1;
            LCosto.text=[valores objectForKey:@"Costo"];
            LUnidades.text=[valores objectForKey:@"Unidades"];
            LRendimiento.text=[valores objectForKey:@"Rendimiento"];
            LTotal.text=[valores objectForKey:@"Total"];
            [plus setUserInteractionEnabled:YES];
            [minus setUserInteractionEnabled:YES];
            activo=FALSE;
            activado=TRUE;
        }
    }
}


-(void)suma{
    //Numero
    int numero=[[valores objectForKey:@"Numero"]intValue]+1;
    NSString *nuevonumero=[NSString stringWithFormat:@"%i",numero];
    LNumero.text=nuevonumero;
    [valores setObject:nuevonumero forKey:@"Numero"];
    //Costo Y Acumulado
    NSString *texto1=[valores objectForKey:@"Costo"];
    //NSLog(@"Costo %@",texto1);
    NSString *texto2=[valores objectForKey:@"CostoAcumulado"];
    //NSLog(@"Costo Acumulado%@",texto2);
    float Costo=[[texto1 substringFromIndex:1]floatValue];
    float NuevoCosto=Costo*[self randomFloatBetween:0.99 and:1.05];
    //NSLog(@"Nuevo Costo%f",NuevoCosto);
    float CostoAcumulado=[[texto2 substringFromIndex:1]floatValue]+Costo;
    NSString *SCosto=[NSString stringWithFormat:@"$%.02f",NuevoCosto];
    NSString *SCostoAcumulado=[NSString stringWithFormat:@"$%.02f",CostoAcumulado];
    [valores setObject:SCosto forKey:@"Costo"];
    [valores setObject:SCostoAcumulado forKey:@"CostoAcumulado"];
    LCosto.text=SCosto;
    //NSLog(@"1");
    //Rendimiento
    NSString *texto3=[valores objectForKey:@"Rendimiento"];
    NSString *texto4=[valores objectForKey:@"RendimientoAcumulado"];
    float Ren=[texto3 floatValue];
    float NuevoRen=Ren*[self randomFloatBetween:0.95 and:1.01];
    float RenAcumulado=[texto4 floatValue]+NuevoRen;
    NSString *SRen=[NSString stringWithFormat:@"%.02f",NuevoRen];
    NSString *SRenAcumulado=[NSString stringWithFormat:@"%.02f",RenAcumulado];
    [valores setObject:SRen forKey:@"Rendimiento"];
    [valores setObject:SRenAcumulado forKey:@"RendimientoAcumulado"];
    LRendimiento.text=SRen;
    //Animacion
    [UIView animateWithDuration:1.0 animations:^{
        LCosto.layer.backgroundColor = [UIColor colorWithRed:.94 green:.77 blue:.10 alpha:1].CGColor;
    } completion:NULL];
    [UIView animateWithDuration:3.0 animations:^{
        LCosto.layer.backgroundColor = [UIColor clearColor].CGColor;
    } completion:NULL];
    [UIView animateWithDuration:1.0 animations:^{
        LRendimiento.layer.backgroundColor = [UIColor colorWithRed:.94 green:.77 blue:.10 alpha:1].CGColor;
    } completion:NULL];
    [UIView animateWithDuration:3.0 animations:^{
        LRendimiento.layer.backgroundColor = [UIColor clearColor].CGColor;
    } completion:NULL];
    [self.delegadoA RPLUS];
    //NSLog(@"1");
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
        //Rendimiento
        NSString *texto3=[valores objectForKey:@"Rendimiento"];
        NSString *texto4=[valores objectForKey:@"RendimientoAcumulado"];
        float Ren=[texto3 floatValue];
        float NuevoRen=Ren*[self randomFloatBetween:0.98 and:1.05];
        float RenAcumulado=[texto4 floatValue]+NuevoRen;
        NSString *SRen=[NSString stringWithFormat:@"%.02f",NuevoRen];
        NSString *SRenAcumulado=[NSString stringWithFormat:@"%.02f",RenAcumulado];
        [valores setObject:SRen forKey:@"Rendimiento"];
        [valores setObject:SRenAcumulado forKey:@"RendimientoAcumulado"];
        LRendimiento.text=SRen;
        [UIView animateWithDuration:1.0 animations:^{
            LCosto.layer.backgroundColor = [UIColor colorWithRed:.87 green:.30 blue:.37 alpha:1].CGColor;
        } completion:NULL];
        [UIView animateWithDuration:3.0 animations:^{
            LCosto.layer.backgroundColor = [UIColor clearColor].CGColor;
        } completion:NULL];
        [UIView animateWithDuration:1.0 animations:^{
            LRendimiento.layer.backgroundColor = [UIColor colorWithRed:.87 green:.30 blue:.37 alpha:1].CGColor;
        } completion:NULL];
        [UIView animateWithDuration:3.0 animations:^{
            LRendimiento.layer.backgroundColor = [UIColor clearColor].CGColor;
        } completion:NULL];
        [self.delegadoA RMINUS];
    }
    else if (numero==0){
        [valores setObject:@"0" forKey:@"Rendimiento Acumulado"];
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
    if (unidadest<=[[valores objectForKey:@"Unidades"] floatValue]+0.2) {

    if ([LNumero.text floatValue]>0) {
        NSString *costoacumulado=[valores objectForKey:@"CostoAcumulado"];
        float fcostoacumulado=[[costoacumulado substringFromIndex:1] floatValue];
        NSString *rendimientoacumulado=[valores objectForKey:@"RendimientoAcumulado"];
        float frendimientoacumulado=[rendimientoacumulado floatValue];
        float unidadestt=frendimientoacumulado*.01;
        unidadest=unidadest+unidadestt;
        //NSLog(@"Unidades Totales %f",unidadest);
        NSString *totalunidades=[valores objectForKey:@"Unidades"];
        float ftotalunidades=[totalunidades floatValue];
        float progreso=0;
        if (unidadest>0) {
            if (progreso<1) {
                progreso=unidadest/ftotalunidades;
            }
        }
        else{
            progreso=0;
        }
        
        //NSLog(@"Progreso %f",progreso);
        LDProgress.progress=progreso;
        float costost=fcostoacumulado*.01;
        costos=costos+costost;
        NSString *SCostoTotal=[NSString stringWithFormat:@"$%.02f",costos];
        LTotal.text=SCostoTotal;
        }
    }

    
    
}
-(void)progress2{
    if (unidadest<=[[valores objectForKey:@"Unidades"] floatValue]+0.2) {
        
        if ([LNumero.text floatValue]>0) {
            NSString *costoacumulado=[valores objectForKey:@"CostoAcumulado"];
            float fcostoacumulado=[[costoacumulado substringFromIndex:1] floatValue];
            NSString *rendimientoacumulado=[valores objectForKey:@"RendimientoAcumulado"];
            float frendimientoacumulado=[rendimientoacumulado floatValue];
            float unidadestt=frendimientoacumulado*.1;
            unidadest=unidadest+unidadestt;
            //NSLog(@"Unidades Totales %f",unidadest);
            NSString *totalunidades=[valores objectForKey:@"Unidades"];
            float ftotalunidades=[totalunidades floatValue];
            float progreso=0;
            if (unidadest>0) {
                if (progreso<1) {
                progreso=unidadest/ftotalunidades;
                }
            }
            else{
                progreso=0;
            }
            
            //NSLog(@"Progreso %f",progreso);
            LDProgress.progress=progreso;
            float costost=fcostoacumulado*.1;
            costos=costos+costost;
            NSString *SCostoTotal=[NSString stringWithFormat:@"$%.02f",costos];
            LTotal.text=SCostoTotal;
        }
        else {
            
            
            
        }
    }
    
}




- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



@end
