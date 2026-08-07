//
//  ViewController.m
//  CMSimulator
//
//  Created by Enrique Galicia on 26/10/15.
//  Copyright © 2015 Enrique Galicia. All rights reserved.
//

#import "ViewController.h"

static NSString * const kCMSimulatorLeaderboardID = @"com.magarchitecture.CMSimulator.constructionmaster";

@interface ViewController ()
@property (nonatomic, assign) BOOL introShown;
@property (nonatomic, assign) BOOL resultShown;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    riesgo.pspi=1;
    calidad.pspi=1;
    NSString *rpspi=[NSString stringWithFormat:@"%f",riesgo.pspi];
    NSString *cpspi=[NSString stringWithFormat:@"%f",calidad.pspi];
    valores=[[NSMutableDictionary alloc]init];
    
    [valores setObject:rpspi forKey:@"GRisk"];
    [valores setObject:cpspi forKey:@"GQuality"];
    [valores setObject:@"1" forKey:@"Risk"];
    [valores setObject:@"1" forKey:@"Quality"];
    [valores setObject:@"1" forKey:@"Planning"];
    [valores setObject:@"1" forKey:@"Procurement"];
    [valores setObject:@"1" forKey:@"Communications"];
    [valores setObject:@"1" forKey:@"Training"];
    [valores setObject:@"0" forKey:@"Progress"];
    
    RR1=[[Recurso alloc]init];
    RR1.delegadoA=self;
    RR1.view.frame= IvR1.frame;
    [self.view addSubview:RR1.view];
    
    [RR1 setvalues:@"Design.jpeg" titulo:@"Design" costo:@"$700.00" unidades:@"48" rendimiento:@"1" total:@"$0.00" progreso:0.0 start:@"0.0"];
    
    RR2=[[Recurso alloc]init];
    RR2.delegadoA=self;
    RR2.view.frame= IvR2.frame;
    [self.view addSubview:RR2.view];
    
    [RR2 setvalues:@"Structure.jpeg" titulo:@"Structure" costo:@"$900.00" unidades:@"48" rendimiento:@"1" total:@"$0.00" progreso:0.0 start:@"20.0"];

    RR3=[[Recurso alloc]init];
    RR3.delegadoA=self;
    RR3.view.frame= IvR3.frame;
    [self.view addSubview:RR3.view];
    
    [RR3 setvalues:@"Engineering.jpeg" titulo:@"Engineering" costo:@"$1200.00" unidades:@"62" rendimiento:@"1" total:@"$0.00" progreso:0.0 start:@"30.0"];

    RR4=[[Recurso alloc]init];
    RR4.delegadoA=self;
    RR4.view.frame= IvR4.frame;
    [self.view addSubview:RR4.view];
    
    [RR4 setvalues:@"Construction.jpeg" titulo:@"Construction" costo:@"$2500.00" unidades:@"264" rendimiento:@"1" total:@"$0.00" progreso:0.0 start:@"50.0"];

    RR5=[[Recurso alloc]init];
    RR5.delegadoA=self;
    RR5.view.frame= IvR5.frame;
    [self.view addSubview:RR5.view];
    
    [RR5 setvalues:@"IHS.jpeg" titulo:@"IHS & IAA" costo:@"$1800.00" unidades:@"214" rendimiento:@"1" total:@"$0.00" progreso:0.0 start:@"55.0"];

    RR6=[[Recurso alloc]init];
    RR6.delegadoA=self;
    RR6.view.frame= IvR6.frame;
    [self.view addSubview:RR6.view];
    
    [RR6 setvalues:@"IES.jpeg" titulo:@"IEL & IES" costo:@"$1600.00" unidades:@"364" rendimiento:@"1" total:@"$0.00" progreso:0.0 start:@"60.0"];
    
    RP1=[[Potenciadores alloc]init];
    RP1.delA=self;
    RP1.view.frame= IvP1.frame;
    [self.view addSubview:RP1.view];
    
    [RP1 setvalues:@"Planning.jpeg" titulo:@"Planning" costo:@"$600.00" total:@"$0.00" start:@"0.0" affects:@"Labor Rates, Starts, Quality and Communications"];
    
    RP2=[[Potenciadores alloc]init];
    RP2.delA=self;
    RP2.view.frame= IvP2.frame;
    [self.view addSubview:RP2.view];
    
    [RP2 setvalues:@"Procurement.png" titulo:@"Procurement" costo:@"$800.00" total:@"$0.00" start:@"15.0" affects:@"Resources Cost, Support Costs, Planning and Risk"];

    
    RP3=[[Potenciadores alloc]init];
    RP3.delA=self;
    RP3.view.frame= IvP3.frame;
    [self.view addSubview:RP3.view];
    
    [RP3 setvalues:@"Risk.jpeg" titulo:@"Risk" costo:@"$1000.00" total:@"$0.00"  start:@"35.0" affects:@"Resources Cost, Support Costs, Labor Rates,  Planning and Communications"];

    
    RP4=[[Potenciadores alloc]init];
    RP4.delA=self;
    RP4.view.frame= IvP4.frame;
    [self.view addSubview:RP4.view];
    
    [RP4 setvalues:@"Communications.jpeg" titulo:@"Communications" costo:@"$600.00" total:@"$0.00" start:@"45.0" affects:@"Labor Rates, Procurement and Training"];

    
    RP5=[[Potenciadores alloc]init];
    RP5.delA=self;
    RP5.view.frame= IvP5.frame;
    [self.view addSubview:RP5.view];
    
    [RP5 setvalues:@"Training.jpeg" titulo:@"Training" costo:@"$1500.00" total:@"$0.00" start:@"50.0" affects:@"Cummulate Labor Rates, Costs, Quality and Risk"];

    
    RP6=[[Potenciadores alloc]init];
    RP6.delA=self;
    RP6.view.frame= IvP6.frame;
    [self.view addSubview:RP6.view];
    
    [RP6 setvalues:@"Quality.jpeg" titulo:@"Quality" costo:@"$800.00" total:@"$0.00" start:@"25.0" affects:@"Resources Cost, Support Costs,Labor Rates, Starts, Training and Procurement"];
     totalcost.text=@"$0.00";
    dias=0;
    totaltime.text=[NSString stringWithFormat:@"%i Dias",dias];
    totalprogress.text=@"0.0%";

    gestorbd=[[GestorBD alloc]initwithdatabases];
    self.introShown=NO;
    self.resultShown=NO;
    [self authenticateLocalPlayer];

    // Do any additional setup after loading the view, typically from a nib.
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    if (!self.introShown) {
        self.introShown=YES;
        Intro1=[[Intro alloc]init];
        Intro1.delegado=self;
        Intro1.modalPresentationStyle=UIModalPresentationFullScreen;
        [self presentViewController:Intro1 animated:NO completion:nil];
    }
}

#pragma mark - Intro / Help / Scores navigation

-(void)introPlay{
    [self dismissViewControllerAnimated:YES completion:nil];
}
-(void)introHelp{
    __weak typeof(self) weakSelf = self;
    [self dismissViewControllerAnimated:YES completion:^{
        [weakSelf presentHelp];
    }];
}
-(void)introScores{
    __weak typeof(self) weakSelf = self;
    [self dismissViewControllerAnimated:YES completion:^{
        [weakSelf presentScores];
    }];
}

-(void)presentHelp{
    helpo=[[Help alloc]init];
    helpo.delehelpo=self;
    helpo.modalPresentationStyle=UIModalPresentationOverFullScreen;
    [self presentViewController:helpo animated:YES completion:nil];
}
-(void)exithelp{
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)presentScores{
    ScoresA=[[Scores alloc]init];
    ScoresA.delescore=self;
    ScoresA.modalPresentationStyle=UIModalPresentationFullScreen;
    [self presentViewController:ScoresA animated:YES completion:nil];
}
-(void)exit{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Result / Scores data source

-(void)resultado:(NSMutableDictionary*)arreglo{
    NSDate *hoy=[NSDate date];
    NSDateFormatter *df=[[NSDateFormatter alloc]init];
    df.dateFormat=@"dd";
    NSString *dia=[df stringFromDate:hoy];
    df.dateFormat=@"MM";
    NSString *mes=[df stringFromDate:hoy];
    df.dateFormat=@"yyyy";
    NSString *ano=[df stringFromDate:hoy];

    NSString *nombre=[arreglo objectForKey:@"Nombre"];
    if (nombre==nil || [nombre length]==0) {
        nombre=@"Player";
    }

    NSArray *valoresguardar=[NSArray arrayWithObjects:nombre,[arreglo objectForKey:@"Costo"],[arreglo objectForKey:@"Tiempo"],dia,mes,ano, nil];
    [gestorbd saveinfoalways:valoresguardar val:@"BDN1S" tabla:@"SCORES"];

    [self reportScore];

    __weak typeof(self) weakSelf = self;
    [self dismissViewControllerAnimated:YES completion:^{
        [weakSelf presentScores];
    }];
}

-(NSMutableArray*)changescore:(NSString*)score{
    return [[NSMutableArray alloc]init];
}

-(NSMutableDictionary*)obtenerinformacion2{
    NSArray *columnas=[NSArray arrayWithObjects:@"Id",@"Nombre",@"Costo",@"Tiempo",@"Dia",@"Mes",@"Ano", nil];
    NSDictionary *tabla=[gestorbd getalltb:@"SCORES" val:@"BDN1"];

    NSArray *ids=[tabla objectForKey:@"Id"];
    NSUInteger total=[ids count];
    NSMutableArray *indices=[NSMutableArray arrayWithCapacity:total];
    for (NSUInteger i=0; i<total; i++) {
        [indices addObject:[NSNumber numberWithUnsignedInteger:i]];
    }

    NSMutableDictionary *resultado=[[NSMutableDictionary alloc]init];
    [resultado setObject:[self ordenarTabla:tabla indices:indices columnas:columnas porCampo:@"Costo" ascendente:YES] forKey:@"Costos"];
    [resultado setObject:[self ordenarTabla:tabla indices:indices columnas:columnas porCampo:@"Tiempo" ascendente:YES] forKey:@"Tiempos"];
    [resultado setObject:[self ordenarTablaCombinado:tabla indices:indices columnas:columnas] forKey:@"Total"];

    return resultado;
}

-(NSDictionary*)ordenarTabla:(NSDictionary*)tabla indices:(NSArray*)indices columnas:(NSArray*)columnas porCampo:(NSString*)campo ascendente:(BOOL)ascendente{
    NSArray *valoresCampo=[tabla objectForKey:campo];
    NSArray *ordenados=[indices sortedArrayUsingComparator:^NSComparisonResult(NSNumber *a, NSNumber *b) {
        float va=[[valoresCampo objectAtIndex:[a unsignedIntegerValue]] floatValue];
        float vb=[[valoresCampo objectAtIndex:[b unsignedIntegerValue]] floatValue];
        if (va<vb) return ascendente ? NSOrderedAscending : NSOrderedDescending;
        if (va>vb) return ascendente ? NSOrderedDescending : NSOrderedAscending;
        return NSOrderedSame;
    }];
    return [self reordenarColumnas:tabla columnas:columnas ordenados:ordenados];
}

-(NSDictionary*)ordenarTablaCombinado:(NSDictionary*)tabla indices:(NSArray*)indices columnas:(NSArray*)columnas{
    NSArray *costos=[tabla objectForKey:@"Costo"];
    NSArray *tiempos=[tabla objectForKey:@"Tiempo"];
    float maxCosto=0.0f, maxTiempo=0.0f;
    for (NSString *c in costos) { maxCosto=MAX(maxCosto,[c floatValue]); }
    for (NSString *t in tiempos) { maxTiempo=MAX(maxTiempo,[t floatValue]); }
    if (maxCosto<=0) maxCosto=1;
    if (maxTiempo<=0) maxTiempo=1;

    NSArray *ordenados=[indices sortedArrayUsingComparator:^NSComparisonResult(NSNumber *a, NSNumber *b) {
        NSUInteger ia=[a unsignedIntegerValue], ib=[b unsignedIntegerValue];
        float va=([[costos objectAtIndex:ia] floatValue]/maxCosto)+([[tiempos objectAtIndex:ia] floatValue]/maxTiempo);
        float vb=([[costos objectAtIndex:ib] floatValue]/maxCosto)+([[tiempos objectAtIndex:ib] floatValue]/maxTiempo);
        if (va<vb) return NSOrderedAscending;
        if (va>vb) return NSOrderedDescending;
        return NSOrderedSame;
    }];
    return [self reordenarColumnas:tabla columnas:columnas ordenados:ordenados];
}

-(NSDictionary*)reordenarColumnas:(NSDictionary*)tabla columnas:(NSArray*)columnas ordenados:(NSArray*)ordenados{
    NSMutableDictionary *salida=[[NSMutableDictionary alloc]init];
    for (NSString *col in columnas) {
        NSArray *origen=[tabla objectForKey:col];
        NSMutableArray *destino=[[NSMutableArray alloc]init];
        for (NSNumber *idx in ordenados) {
            NSUInteger i=[idx unsignedIntegerValue];
            if (origen!=nil && i<[origen count]) {
                [destino addObject:[origen objectAtIndex:i]];
            }
        }
        [salida setObject:destino forKey:col];
    }
    return salida;
}

#pragma mark - Game Center

-(void)authenticateLocalPlayer{
    __weak typeof(self) weakSelf = self;
    GKLocalPlayer *localPlayer=[GKLocalPlayer localPlayer];
    localPlayer.authenticateHandler=^(UIViewController * _Nullable viewController, NSError * _Nullable error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        if (viewController!=nil) {
            [strongSelf presentViewController:viewController animated:YES completion:nil];
        }
        else if (localPlayer.isAuthenticated) {
            NSLog(@"Game Center: authenticated");
        }
        else {
            NSLog(@"Game Center unavailable: %@",error.localizedDescription);
        }
    };
}

-(void)reportScore{
    if (![[GKLocalPlayer localPlayer] isAuthenticated]) { return; }
    NSString *texto=totalcost.text;
    if ([texto length]>1) {
        NSInteger puntuacion=(NSInteger)[[texto substringFromIndex:1] floatValue];
        [GKLeaderboard submitScore:puntuacion
                            context:0
                             player:[GKLocalPlayer localPlayer]
                     leaderboardIDs:@[kCMSimulatorLeaderboardID]
                  completionHandler:^(NSError * _Nullable error) {
            if (error) {
                NSLog(@"Game Center score submission failed: %@",error.localizedDescription);
            }
        }];
    }
}

-(void)showLeaderboardAndAchievements:(BOOL)shouldShowLeaderboard{
    if (![[GKLocalPlayer localPlayer] isAuthenticated]) { return; }
    GKGameCenterViewController *gc=[[GKGameCenterViewController alloc]initWithState: shouldShowLeaderboard ? GKGameCenterViewControllerStateLeaderboards : GKGameCenterViewControllerStateAchievements];
    gc.gameCenterDelegate=self;
    [self presentViewController:gc animated:YES completion:nil];
}

-(void)gameCenterViewControllerDidFinish:(GKGameCenterViewController *)gameCenterViewController{
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    UITouch *touch =[touches anyObject];
    if ([touch view]==play) {
        [RR1 play];
        [RR2 play];
        [RR3 play];
        [RR4 play];
        [RR5 play];
        [RR6 play];
        [RP1 play];
        [RP2 play];
        [RP3 play];
        [RP4 play];
        [RP5 play];
        [RP6 play];
        if ([Temporal isValid]) {
            [Temporal invalidate];
            Temporal=nil;
        }
        Temporal=[NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(progress) userInfo:nil repeats:YES];

    }
    else if([touch view]==pause){
        [RR1 pause];
        [RR2 pause];
        [RR3 pause];
        [RR4 pause];
        [RR5 pause];
        [RR6 pause];
        [RP1 pause];
        [RP2 pause];
        [RP3 pause];
        [RP4 pause];
        [RP5 pause];
        [RP6 pause];
        if ([Temporal isValid]) {
            [Temporal invalidate];
            Temporal=nil;
        }
    }
    else if([touch view]==fastforward){
        [RR1 fastforward];
        [RR2 fastforward];
        [RR3 fastforward];
        [RR4 fastforward];
        [RR5 fastforward];
        [RR6 fastforward];
        [RP1 fastforward];
        [RP2 fastforward];
        [RP3 fastforward];
        [RP4 fastforward];
        [RP5 fastforward];
        [RP6 fastforward];
        if ([Temporal isValid]) {
            [Temporal invalidate];
            Temporal=nil;
        }
        Temporal=[NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(progress2) userInfo:nil repeats:YES];
    }
    else if([touch view]==help){
        [self presentHelp];
    }
    else if([touch view]==scores){
        [self presentScores];
    }
    else if([touch view]==gamecenter){
        [self showLeaderboardAndAchievements:YES];
    }

}
-(void)progress{

    float ftcost=[[RR1.LTotal.text substringFromIndex:1]floatValue]+[[RR2.LTotal.text substringFromIndex:1]floatValue]+[[RR3.LTotal.text substringFromIndex:1]floatValue]+[[RR4.LTotal.text substringFromIndex:1]floatValue]+[[RR5.LTotal.text substringFromIndex:1]floatValue]+[[RR6.LTotal.text substringFromIndex:1]floatValue]+[[RP1.LTotal.text substringFromIndex:1]floatValue]+[[RP2.LTotal.text substringFromIndex:1]floatValue]+[[RP3.LTotal.text substringFromIndex:1]floatValue]+[[RP4.LTotal.text substringFromIndex:1]floatValue]+[[RP5.LTotal.text substringFromIndex:1]floatValue]+[[RP6.LTotal.text substringFromIndex:1]floatValue];
    totalcost.text=[NSString stringWithFormat:@"$%.02f",ftcost];
    fdias=fdias+.01;
    dias=fdias;
    int hr=(fdias-dias)*8;
    totaltime.text=[NSString stringWithFormat:@"%i Dias %i Horas",dias,hr];
    float unidadestotales=[RR1.LUnidades.text floatValue]+[RR2.LUnidades.text floatValue]+[RR3.LUnidades.text floatValue]+[RR4.LUnidades.text floatValue]+[RR5.LUnidades.text floatValue]+[RR6.LUnidades.text floatValue];
    //NSLog(@"Totales%f",unidadestotales);
    float ftprog=((([RR1.LUnidades.text floatValue]/unidadestotales)*RR1.LDProgress.progress)+(([RR2.LUnidades.text floatValue]/unidadestotales)*RR2.LDProgress.progress)+(([RR3.LUnidades.text floatValue]/unidadestotales)*RR3.LDProgress.progress)+(([RR4.LUnidades.text floatValue]/unidadestotales)*RR4.LDProgress.progress)+(([RR5.LUnidades.text floatValue]/unidadestotales)*RR5.LDProgress.progress)+(([RR6.LUnidades.text floatValue]/unidadestotales)*RR6.LDProgress.progress))*100;
    //NSLog(@"progreso%f",ftprog);
    totalprogress.text=[NSString stringWithFormat:@"%.02f%%",ftprog];
    [RR1 receiveprogress:ftprog];
    [RR2 receiveprogress:ftprog];
    [RR3 receiveprogress:ftprog];
    [RR4 receiveprogress:ftprog];
    [RR5 receiveprogress:ftprog];
    [RR6 receiveprogress:ftprog];
    [RP1 receiveprogress:ftprog];
    [RP2 receiveprogress:ftprog];
    [RP3 receiveprogress:ftprog];
    [RP4 receiveprogress:ftprog];
    [RP5 receiveprogress:ftprog];
    [RP6 receiveprogress:ftprog];
    
    if (ftprog>=100) {
        [RR1 pause];
        [RR2 pause];
        [RR3 pause];
        [RR4 pause];
        [RR5 pause];
        [RR6 pause];
        [RP1 pause];
        [RP2 pause];
        [RP3 pause];
        [RP4 pause];
        [RP5 pause];
        [RP6 pause];
        [self checkForCompletion:ftcost];
    }

}
-(void)progress2{
    float ftcost=[[RR1.LTotal.text substringFromIndex:1]floatValue]+[[RR2.LTotal.text substringFromIndex:1]floatValue]+[[RR3.LTotal.text substringFromIndex:1]floatValue]+[[RR4.LTotal.text substringFromIndex:1]floatValue]+[[RR5.LTotal.text substringFromIndex:1]floatValue]+[[RR6.LTotal.text substringFromIndex:1]floatValue];
    
    totalcost.text=[NSString stringWithFormat:@"$%.02f",ftcost];
    fdias=fdias+.1;
    dias=fdias;
    int hr=(fdias-dias)*8;
    totaltime.text=[NSString stringWithFormat:@"%i Dias %i Horas",dias,hr];
    float unidadestotales=[RR1.LUnidades.text floatValue]+[RR2.LUnidades.text floatValue]+[RR3.LUnidades.text floatValue]+[RR4.LUnidades.text floatValue]+[RR5.LUnidades.text floatValue]+[RR6.LUnidades.text floatValue];
    //NSLog(@"Totales%f",unidadestotales);
    float ftprog=((([RR1.LUnidades.text floatValue]/unidadestotales)*RR1.LDProgress.progress)+(([RR2.LUnidades.text floatValue]/unidadestotales)*RR2.LDProgress.progress)+(([RR3.LUnidades.text floatValue]/unidadestotales)*RR3.LDProgress.progress)+(([RR4.LUnidades.text floatValue]/unidadestotales)*RR4.LDProgress.progress)+(([RR5.LUnidades.text floatValue]/unidadestotales)*RR5.LDProgress.progress)+(([RR6.LUnidades.text floatValue]/unidadestotales)*RR6.LDProgress.progress))*100;
    //NSLog(@"progreso%f",ftprog);
    totalprogress.text=[NSString stringWithFormat:@"%.02f%%",ftprog];
    [RR1 receiveprogress:ftprog];
    [RR2 receiveprogress:ftprog];
    [RR3 receiveprogress:ftprog];
    [RR4 receiveprogress:ftprog];
    [RR5 receiveprogress:ftprog];
    [RR6 receiveprogress:ftprog];
    [RP1 receiveprogress:ftprog];
    [RP2 receiveprogress:ftprog];
    [RP3 receiveprogress:ftprog];
    [RP4 receiveprogress:ftprog];
    [RP5 receiveprogress:ftprog];
    [RP6 receiveprogress:ftprog];
    if (ftprog>=100) {
        [RR1 pause];
        [RR2 pause];
        [RR3 pause];
        [RR4 pause];
        [RR5 pause];
        [RR6 pause];
        [RP1 pause];
        [RP2 pause];
        [RP3 pause];
        [RP4 pause];
        [RP5 pause];
        [RP6 pause];
        [self checkForCompletion:ftcost];
    }

}

#pragma mark - Simulation completion

-(void)checkForCompletion:(float)ftcost{
    if (self.resultShown) { return; }
    self.resultShown=YES;
    ResultA=[[Result alloc]init];
    ResultA.deleresult=self;
    ResultA.fcosto=ftcost;
    ResultA.ftiempo=fdias;
    ResultA.modalPresentationStyle=UIModalPresentationFullScreen;
    [self presentViewController:ResultA animated:YES completion:nil];
}

- (float)randomFloatBetween:(float)smallNumber and:(float)bigNumber {
    float diff = bigNumber - smallNumber;
    return (((float) (arc4random() % ((unsigned)RAND_MAX + 1)) / RAND_MAX) * diff) + smallNumber;
}

-(void)RPLUS{
    [self f01modindicadormasmenosgraficaconfig:@"GRisk" rana:.90 ranb:0.99 gra:riesgo config:@"%.02f"];
    [self f01modindicadormasmenosgraficaconfig:@"GQuality" rana:.90 ranb:0.99 gra:calidad config:@"%.02f"];
    //NSLog(@"Añadi Recursos");
    
}
-(void)RMINUS{
    [self f01modindicadormasmenosgraficaconfig:@"GRisk" rana:1.01 ranb:1.05 gra:riesgo config:@"%.02f"];
    [self f01modindicadormasmenosgraficaconfig:@"GQuality" rana:1.01 ranb:1.05 gra:calidad config:@"%.02f"];
    //NSLog(@"Reste Recursos");
    
}
-(void)f01modindicadormasmenosgraficaconfig:(NSString*)campo rana:(float)rana ranb:(float)ranb gra:(SPI*)gra config:(NSString*)config{
    float fries=[[valores objectForKey:campo] floatValue];
    float friest=fries*[self randomFloatBetween:rana and:ranb];
    double friesd=friest;
    gra.pspi=friesd;
    [gra setNeedsDisplay];
    //NSLog(@"El nuevo Riesgo es %f %f",friest,gra.pspi);
    NSString *sriesgo=[NSString stringWithFormat:config,friest];
    [valores setObject:sriesgo forKey:campo];
    
}
-(float)f02modindicadormasmenosconfigfloat:(NSString*)campo rana:(float)rana ranb:(float)ranb config:(NSString*)config{
    float fpla=[[valores objectForKey:campo] floatValue];
    float fplat=fpla+[self randomFloatBetween:rana and:ranb];
    NSString *spla=[NSString stringWithFormat:config,fplat];
    [valores setObject:spla forKey:campo];
    return fplat;
}
-(void)f03modreccametifacconf:(Recurso*)Rec Campo:(NSString*)campo etiqueta:(UILabel*)etiqueta factor:(float)factor config:(NSString*)config{
    
    int numero=[[Rec.valores objectForKey:@"Numero"] intValue];
    if (numero>0) {
        if ([campo isEqualToString:@"Costo"]) {
            float rend=[[[Rec.valores objectForKey:campo] substringFromIndex:1] floatValue];
            float rend2=[[[Rec.valores objectForKey:@"CostoI"] substringFromIndex:1] floatValue];
            float rendt=rend*factor;
            if (rendt>=(rend2/2)) {
                if (rendt<=(rend2*3)) {
                    NSString *srend=[NSString stringWithFormat:@"$%.02f",rendt];
                    //Animacion
                    [UIView animateWithDuration:1.0 animations:^{
                        etiqueta.layer.backgroundColor = [UIColor greenColor].CGColor;
                    } completion:NULL];
                    [UIView animateWithDuration:3.0 animations:^{
                        etiqueta.layer.backgroundColor = [UIColor whiteColor].CGColor;
                    } completion:NULL];
                    [Rec.valores setObject:srend forKey:campo];
                    etiqueta.text=srend;
                }
                else{
                    NSString *srend=[NSString stringWithFormat:@"$%.02f",rend2*3];
                    //Animacion
                    [UIView animateWithDuration:1.0 animations:^{
                        etiqueta.layer.backgroundColor = [UIColor greenColor].CGColor;
                    } completion:NULL];
                    [UIView animateWithDuration:3.0 animations:^{
                        etiqueta.layer.backgroundColor = [UIColor whiteColor].CGColor;
                    } completion:NULL];
                    [Rec.valores setObject:srend forKey:campo];
                    etiqueta.text=srend;
                }
            }
            else{
                    NSString *srend=[NSString stringWithFormat:@"$%.02f",rend2/2];
                //Animacion
                [UIView animateWithDuration:1.0 animations:^{
                    etiqueta.layer.backgroundColor = [UIColor greenColor].CGColor;
                } completion:NULL];
                [UIView animateWithDuration:3.0 animations:^{
                    etiqueta.layer.backgroundColor = [UIColor whiteColor].CGColor;
                } completion:NULL];
                    [Rec.valores setObject:srend forKey:campo];
                    etiqueta.text=srend;

            }
            
        }
        else{
        float rend=[[Rec.valores objectForKey:campo] floatValue];
        float rend2=[[Rec.valores objectForKey:@"RendimientoI"] floatValue];
        float rendt=rend*factor;
            if (rendt>=(rend2*0.3)) {
                if (rendt<=(rend2*1.8)) {
                    NSString *srend=[NSString stringWithFormat:@"%.02f",rendt];
                    //Animacion
                    [UIView animateWithDuration:1.0 animations:^{
                        etiqueta.layer.backgroundColor = [UIColor greenColor].CGColor;
                    } completion:NULL];
                    [UIView animateWithDuration:3.0 animations:^{
                        etiqueta.layer.backgroundColor = [UIColor whiteColor].CGColor;
                    } completion:NULL];
                    [Rec.valores setObject:srend forKey:campo];
                    etiqueta.text=srend;
                }
                else{
                    NSString *srend=[NSString stringWithFormat:@"%.02f",rend2*1.8];
                    //Animacion
                    [UIView animateWithDuration:1.0 animations:^{
                        etiqueta.layer.backgroundColor = [UIColor greenColor].CGColor;
                    } completion:NULL];
                    [UIView animateWithDuration:3.0 animations:^{
                        etiqueta.layer.backgroundColor = [UIColor whiteColor].CGColor;
                    } completion:NULL];
                    [Rec.valores setObject:srend forKey:campo];
                    etiqueta.text=srend;
                }
            }
            else{
                    NSString *srend=[NSString stringWithFormat:@"%.02f",rend2*.3];
                //Animacion
                [UIView animateWithDuration:1.0 animations:^{
                    etiqueta.layer.backgroundColor = [UIColor greenColor].CGColor;
                } completion:NULL];
                [UIView animateWithDuration:3.0 animations:^{
                    etiqueta.layer.backgroundColor = [UIColor whiteColor].CGColor;
                } completion:NULL];
                    [Rec.valores setObject:srend forKey:campo];
                    etiqueta.text=srend;

            }

        }
    }
    
}
-(void)f04modreccamfaccon:(Recurso*)Rec Campo:(NSString*)campo factor:(float)factor config:(NSString*)config{
    int numero=[[Rec.valores objectForKey:@"Numero"] intValue];
    if (numero>0) {
        float rend=[[Rec.valores objectForKey:campo] floatValue];
        NSLog(@"Rend%f,Factor%f",rend,factor);
        float rendt=rend*factor;
        NSString *srend=[NSString stringWithFormat:config,rendt];
        
        //Animacion
        /*[UIView animateWithDuration:1.0 animations:^{
            Rec.LDProgress.color = [UIColor colorWithRed:0.00f green:0.00f blue:0.64f alpha:1.00f];
        } completion:NULL];
        [UIView animateWithDuration:3.0 animations:^{
              Rec.LDProgress.color = [UIColor colorWithRed:0.00f green:0.64f blue:0.00f alpha:1.00f];
        } completion:NULL];*/

        [Rec.valores setObject:srend forKey:campo];
    }
}
-(void)f05modindicadorcamfacgracon:(NSString*)campo factor:(float)factor gra:(SPI*)gra config:(NSString*)config{
    float fries=[[valores objectForKey:campo] floatValue];
    float friest=fries*factor;
    if (friest>0.5) {
        if (friest<1.5) {
            double friesd=friest;
            gra.pspi=friesd;
            [gra setNeedsDisplay];
            //NSLog(@"El nuevo Riesgo es %f %f",friest,gra.pspi);
            NSString *sriesgo=[NSString stringWithFormat:config,friest];
            [valores setObject:sriesgo forKey:campo];
        }
        else{
            double friesd=1.5;
            gra.pspi=friesd;
            [gra setNeedsDisplay];
            //NSLog(@"El nuevo Riesgo es %f %f",friest,gra.pspi);
            NSString *sriesgo=[NSString stringWithFormat:config,friest];
            [valores setObject:sriesgo forKey:campo];
        }
    }
    else{
        double friesd=0.5;
        gra.pspi=friesd;
        [gra setNeedsDisplay];
        //NSLog(@"El nuevo Riesgo es %f %f",friest,gra.pspi);
        NSString *sriesgo=[NSString stringWithFormat:config,friest];
        [valores setObject:sriesgo forKey:campo];
    }
   
}
-(void)f06modcamfacconf:(NSString*)campo factor:(float)factor config:(NSString*)config{
    if ([campo isEqualToString:@"Planning"]) {
        //Animacion
        [UIView animateWithDuration:1.0 animations:^{
            RP1.LTitulo.layer.backgroundColor = [UIColor greenColor].CGColor;
        } completion:NULL];
        [UIView animateWithDuration:3.0 animations:^{
            RP1.LTitulo.layer.backgroundColor = [UIColor whiteColor].CGColor;
        } completion:NULL];

    }
    if ([campo isEqualToString:@"Procurement"]) {
        //Animacion
        [UIView animateWithDuration:1.0 animations:^{
            RP2.LTitulo.layer.backgroundColor = [UIColor greenColor].CGColor;
        } completion:NULL];
        [UIView animateWithDuration:3.0 animations:^{
            RP2.LTitulo.layer.backgroundColor = [UIColor whiteColor].CGColor;
        } completion:NULL];
    }
    if ([campo isEqualToString:@"Risk"]) {
        //Animacion
        [UIView animateWithDuration:1.0 animations:^{
            RP3.LTitulo.layer.backgroundColor = [UIColor greenColor].CGColor;
        } completion:NULL];
        [UIView animateWithDuration:3.0 animations:^{
            RP3.LTitulo.layer.backgroundColor = [UIColor whiteColor].CGColor;
        } completion:NULL];
    }
    if ([campo isEqualToString:@"Comunications"]) {
        //Animacion
        [UIView animateWithDuration:1.0 animations:^{
            RP4.LTitulo.layer.backgroundColor = [UIColor greenColor].CGColor;
        } completion:NULL];
        [UIView animateWithDuration:3.0 animations:^{
            RP4.LTitulo.layer.backgroundColor = [UIColor whiteColor].CGColor;
        } completion:NULL];
    }
    if ([campo isEqualToString:@"Training"]) {
        //Animacion
        [UIView animateWithDuration:1.0 animations:^{
            RP5.LTitulo.layer.backgroundColor = [UIColor greenColor].CGColor;
        } completion:NULL];
        [UIView animateWithDuration:3.0 animations:^{
            RP5.LTitulo.layer.backgroundColor = [UIColor whiteColor].CGColor;
        } completion:NULL];
    }
    if ([campo isEqualToString:@"Quality"]) {
        //Animacion
        [UIView animateWithDuration:1.0 animations:^{
            RP6.LTitulo.layer.backgroundColor = [UIColor greenColor].CGColor;
        } completion:NULL];
        [UIView animateWithDuration:3.0 animations:^{
            RP6.LTitulo.layer.backgroundColor = [UIColor whiteColor].CGColor;
        } completion:NULL];
    }

        float rend=[[valores objectForKey:campo] floatValue];
        float rendt=rend*factor;
        if (rendt>0.3) {
            if (rendt<1.8) {
                NSString *srend=[NSString stringWithFormat:config,rendt];
                
                [valores setObject:srend forKey:campo];        }
        else{
            NSString *srend=[NSString stringWithFormat:config,rendt];
            [valores setObject:srend forKey:campo];
        }
    }
    else{
        NSString *srend=[NSString stringWithFormat:config,rendt];
        [valores setObject:srend forKey:campo];
    }
    
}
-(void)f07modpotcametifacconf:(Potenciadores*)Rec Campo:(NSString*)campo etiqueta:(UILabel*)etiqueta factor:(float)factor config:(NSString*)config{
    int numero=[[Rec.valores objectForKey:@"Numero"] intValue];
    if (numero>0) {
        if ([campo isEqualToString:@"Costo"]) {
            float rend=[[[Rec.valores objectForKey:campo] substringFromIndex:1] floatValue];
            float rend2=[[[Rec.valores objectForKey:@"CostoI"] substringFromIndex:1] floatValue];
            float rendt=rend*factor;
            if (rendt>=(rend2/2)) {
                if (rendt<=(rend2*3)) {
                    NSString *srend=[NSString stringWithFormat:@"$%.02f",rendt];
                    //Animacion
                    [UIView animateWithDuration:1.0 animations:^{
                        etiqueta.layer.backgroundColor = [UIColor greenColor].CGColor;
                    } completion:NULL];
                    [UIView animateWithDuration:3.0 animations:^{
                        etiqueta.layer.backgroundColor = [UIColor whiteColor].CGColor;
                    } completion:NULL];
                    [Rec.valores setObject:srend forKey:campo];
                    etiqueta.text=srend;
                }
                else{
                    NSString *srend=[NSString stringWithFormat:@"$%.02f",rend2*3];
                    //Animacion
                    [UIView animateWithDuration:1.0 animations:^{
                        etiqueta.layer.backgroundColor = [UIColor greenColor].CGColor;
                    } completion:NULL];
                    [UIView animateWithDuration:3.0 animations:^{
                        etiqueta.layer.backgroundColor = [UIColor whiteColor].CGColor;
                    } completion:NULL];
                    [Rec.valores setObject:srend forKey:campo];
                    etiqueta.text=srend;
                }
            }
            else{
                NSString *srend=[NSString stringWithFormat:@"$%.02f",rend2/2];
                //Animacion
                [UIView animateWithDuration:1.0 animations:^{
                    etiqueta.layer.backgroundColor = [UIColor greenColor].CGColor;
                } completion:NULL];
                [UIView animateWithDuration:3.0 animations:^{
                    etiqueta.layer.backgroundColor = [UIColor whiteColor].CGColor;
                } completion:NULL];
                [Rec.valores setObject:srend forKey:campo];
                etiqueta.text=srend;
                
            }
            
        }
        else{
            float rend=[[Rec.valores objectForKey:campo] floatValue];
            float rend2=[[Rec.valores objectForKey:@"RendimientoI"] floatValue];
            float rendt=rend*factor;
            if (rendt>=(rend2*0.3)) {
                if (rendt<=(rend2*1.8)) {
                    NSString *srend=[NSString stringWithFormat:@"%.02f",rendt];
                    //Animacion
                    [UIView animateWithDuration:1.0 animations:^{
                        etiqueta.layer.backgroundColor = [UIColor greenColor].CGColor;
                    } completion:NULL];
                    [UIView animateWithDuration:3.0 animations:^{
                        etiqueta.layer.backgroundColor = [UIColor whiteColor].CGColor;
                    } completion:NULL];
                    [Rec.valores setObject:srend forKey:campo];
                    etiqueta.text=srend;
                }
                else{
                    NSString *srend=[NSString stringWithFormat:@"%.02f",rend2*1.8];
                    //Animacion
                    [UIView animateWithDuration:1.0 animations:^{
                        etiqueta.layer.backgroundColor = [UIColor greenColor].CGColor;
                    } completion:NULL];
                    [UIView animateWithDuration:3.0 animations:^{
                        etiqueta.layer.backgroundColor = [UIColor whiteColor].CGColor;
                    } completion:NULL];
                    [Rec.valores setObject:srend forKey:campo];
                    etiqueta.text=srend;
                }
            }
            else{
                NSString *srend=[NSString stringWithFormat:@"%.02f",rend2*.3];
                //Animacion
                [UIView animateWithDuration:1.0 animations:^{
                    etiqueta.layer.backgroundColor = [UIColor greenColor].CGColor;
                } completion:NULL];
                [UIView animateWithDuration:3.0 animations:^{
                    etiqueta.layer.backgroundColor = [UIColor whiteColor].CGColor;
                } completion:NULL];
                [Rec.valores setObject:srend forKey:campo];
                etiqueta.text=srend;
                
            }
            
        }
    }
    
}
-(void)f08modpotcamfaccon:(Potenciadores*)Rec Campo:(NSString*)campo factor:(float)factor config:(NSString*)config{
        float rend=[[Rec.valores objectForKey:campo] floatValue];
        float rendt=rend*factor;
        NSLog(@"Start%f,Nuevo%f,Factor%f",rend,rendt,factor);
        NSString *srend=[NSString stringWithFormat:config,rendt];
        NSLog(@"Resultado%@",srend);
    Rec.LStarts.text=[NSString stringWithFormat:@"%@%%",srend];
    //Animacion
    [UIView animateWithDuration:1.0 animations:^{
        Rec.LStarts.layer.backgroundColor = [UIColor greenColor].CGColor;
    } completion:NULL];
    [UIView animateWithDuration:3.0 animations:^{
        Rec.LStarts.layer.backgroundColor = [UIColor whiteColor].CGColor;
    } completion:NULL];
        [Rec.valores setObject:srend forKey:campo];
}
-(void)f09modreccamfaccon:(Recurso*)Rec Campo:(NSString*)campo factor:(float)factor config:(NSString*)config{
        float rend=[[Rec.valores objectForKey:campo] floatValue];
        float rendt=rend*factor;
        NSLog(@"Start%f,Nuevo%f,Factor%f",rend,rendt,factor);
        NSString *srend=[NSString stringWithFormat:config,rendt];
        NSLog(@"Resultado%@",srend);
        Rec.LStarts.text=[NSString stringWithFormat:@"%@%%",srend];
    //Animacion
    [UIView animateWithDuration:1.0 animations:^{
        Rec.LStarts.layer.backgroundColor = [UIColor greenColor].CGColor;
    } completion:NULL];
    [UIView animateWithDuration:3.0 animations:^{
        Rec.LStarts.layer.backgroundColor = [UIColor whiteColor].CGColor;
    } completion:NULL];
    
        [Rec.valores setObject:srend forKey:campo];
}
-(void)f10modreccametifacconf:(Recurso*)Rec Campo:(NSString*)campo etiqueta:(UILabel*)etiqueta factor:(float)factor config:(NSString*)config{
    
    if ([campo isEqualToString:@"Costo"]) {
        float rend=[[[Rec.valores objectForKey:campo] substringFromIndex:1] floatValue];
        float rend2=[[[Rec.valores objectForKey:@"CostoI"] substringFromIndex:1] floatValue];
        float rendt=rend*factor;
        if (rendt>=(rend2/2)) {
            if (rendt<=(rend2*3)) {
                NSString *srend=[NSString stringWithFormat:@"$%.02f",rendt];
                //Animacion
                [UIView animateWithDuration:1.0 animations:^{
                    etiqueta.layer.backgroundColor = [UIColor greenColor].CGColor;
                } completion:NULL];
                [UIView animateWithDuration:3.0 animations:^{
                    etiqueta.layer.backgroundColor = [UIColor whiteColor].CGColor;
                } completion:NULL];

                [Rec.valores setObject:srend forKey:campo];
                etiqueta.text=srend;
            }
            else{
                NSString *srend=[NSString stringWithFormat:@"$%.02f",rend2*3];
                //Animacion
                [UIView animateWithDuration:1.0 animations:^{
                    etiqueta.layer.backgroundColor = [UIColor greenColor].CGColor;
                } completion:NULL];
                [UIView animateWithDuration:3.0 animations:^{
                    etiqueta.layer.backgroundColor = [UIColor whiteColor].CGColor;
                } completion:NULL];

                [Rec.valores setObject:srend forKey:campo];
                etiqueta.text=srend;
            }
        }
        else{
            NSString *srend=[NSString stringWithFormat:@"$%.02f",rend2/2];
            //Animacion
            [UIView animateWithDuration:1.0 animations:^{
                etiqueta.layer.backgroundColor = [UIColor greenColor].CGColor;
            } completion:NULL];
            [UIView animateWithDuration:3.0 animations:^{
                etiqueta.layer.backgroundColor = [UIColor whiteColor].CGColor;
            } completion:NULL];

            [Rec.valores setObject:srend forKey:campo];
            etiqueta.text=srend;
            
        }
        
    }
    else{
        float rend=[[Rec.valores objectForKey:campo] floatValue];
        float rend2=[[Rec.valores objectForKey:@"RendimientoI"] floatValue];
        float rendt=rend*factor;
        
        NSLog(@"Rendimiento Final %f Inicial %f",rendt,rend2);
        if (rendt>=(rend2*0.3)) {
            if (rendt<=(rend2*1.8)) {
                NSString *srend=[NSString stringWithFormat:@"%.02f",rendt];
                //Animacion
                [UIView animateWithDuration:1.0 animations:^{
                    etiqueta.layer.backgroundColor = [UIColor greenColor].CGColor;
                } completion:NULL];
                [UIView animateWithDuration:3.0 animations:^{
                    etiqueta.layer.backgroundColor = [UIColor whiteColor].CGColor;
                } completion:NULL];

                [Rec.valores setObject:srend forKey:campo];
                etiqueta.text=srend;
            }
            else{
                NSString *srend=[NSString stringWithFormat:@"%.02f",rend2*1.8];
                //Animacion
                [UIView animateWithDuration:1.0 animations:^{
                    etiqueta.layer.backgroundColor = [UIColor greenColor].CGColor;
                } completion:NULL];
                [UIView animateWithDuration:3.0 animations:^{
                    etiqueta.layer.backgroundColor = [UIColor whiteColor].CGColor;
                } completion:NULL];

                [Rec.valores setObject:srend forKey:campo];
                etiqueta.text=srend;
            }
        }
        else{
            NSString *srend=[NSString stringWithFormat:@"%.02f",rend2*.3];
            //Animacion
            [UIView animateWithDuration:1.0 animations:^{
                etiqueta.layer.backgroundColor = [UIColor greenColor].CGColor;
            } completion:NULL];
            [UIView animateWithDuration:3.0 animations:^{
                etiqueta.layer.backgroundColor = [UIColor whiteColor].CGColor;
            } completion:NULL];

            [Rec.valores setObject:srend forKey:campo];
            etiqueta.text=srend;
            
        }
    }

    
}
-(void)f11modreccametifacconf:(Potenciadores*)Rec Campo:(NSString*)campo etiqueta:(UILabel*)etiqueta factor:(float)factor config:(NSString*)config{

        if ([campo isEqualToString:@"Costo"]) {
            float rend=[[[Rec.valores objectForKey:campo] substringFromIndex:1] floatValue];
            float rend2=[[[Rec.valores objectForKey:@"CostoI"] substringFromIndex:1] floatValue];
            float rendt=rend*factor;
            if (rendt>=(rend2/2)) {
                if (rendt<=(rend2*3)) {
                    NSString *srend=[NSString stringWithFormat:@"$%.02f",rendt];
                    //Animacion
                    [UIView animateWithDuration:1.0 animations:^{
                        etiqueta.layer.backgroundColor = [UIColor greenColor].CGColor;
                    } completion:NULL];
                    [UIView animateWithDuration:3.0 animations:^{
                        etiqueta.layer.backgroundColor = [UIColor whiteColor].CGColor;
                    } completion:NULL];
                    [Rec.valores setObject:srend forKey:campo];
                    etiqueta.text=srend;
                }
                else{
                    NSString *srend=[NSString stringWithFormat:@"$%.02f",rend2*3];
                    //Animacion
                    [UIView animateWithDuration:1.0 animations:^{
                        etiqueta.layer.backgroundColor = [UIColor greenColor].CGColor;
                    } completion:NULL];
                    [UIView animateWithDuration:3.0 animations:^{
                        etiqueta.layer.backgroundColor = [UIColor whiteColor].CGColor;
                    } completion:NULL];
                    [Rec.valores setObject:srend forKey:campo];
                    etiqueta.text=srend;
                }
            }
            else{
                NSString *srend=[NSString stringWithFormat:@"$%.02f",rend2/2];
                //Animacion
                [UIView animateWithDuration:1.0 animations:^{
                    etiqueta.layer.backgroundColor = [UIColor greenColor].CGColor;
                } completion:NULL];
                [UIView animateWithDuration:3.0 animations:^{
                    etiqueta.layer.backgroundColor = [UIColor whiteColor].CGColor;
                } completion:NULL];
                [Rec.valores setObject:srend forKey:campo];
                etiqueta.text=srend;
                
            }
            
        }
        else{
            float rend=[[Rec.valores objectForKey:campo] floatValue];
            float rend2=[[[Rec.valores objectForKey:@"RendimientoI"] substringFromIndex:1] floatValue];
            float rendt=rend*factor;
            if (rendt>=(rend2*0.3)) {
                if (rendt<=(rend2*1.8)) {
                    NSString *srend=[NSString stringWithFormat:@"%.02f",rendt];
                    //Animacion
                    [UIView animateWithDuration:1.0 animations:^{
                        etiqueta.layer.backgroundColor = [UIColor greenColor].CGColor;
                    } completion:NULL];
                    [UIView animateWithDuration:3.0 animations:^{
                        etiqueta.layer.backgroundColor = [UIColor whiteColor].CGColor;
                    } completion:NULL];
                    [Rec.valores setObject:srend forKey:campo];
                    etiqueta.text=srend;
                }
                else{
                    NSString *srend=[NSString stringWithFormat:@"%.02f",rend2*1.8];
                    //Animacion
                    [UIView animateWithDuration:1.0 animations:^{
                        etiqueta.layer.backgroundColor = [UIColor greenColor].CGColor;
                    } completion:NULL];
                    [UIView animateWithDuration:3.0 animations:^{
                        etiqueta.layer.backgroundColor = [UIColor whiteColor].CGColor;
                    } completion:NULL];
                    [Rec.valores setObject:srend forKey:campo];
                    etiqueta.text=srend;
                }
            }
            else{
                NSString *srend=[NSString stringWithFormat:@"%.02f",rend2*.3];
                //Animacion
                [UIView animateWithDuration:1.0 animations:^{
                    etiqueta.layer.backgroundColor = [UIColor greenColor].CGColor;
                } completion:NULL];
                [UIView animateWithDuration:3.0 animations:^{
                    etiqueta.layer.backgroundColor = [UIColor whiteColor].CGColor;
                } completion:NULL];
                [Rec.valores setObject:srend forKey:campo];
                etiqueta.text=srend;
                
            }
        }
    

    
}


-(void)RPLUSA:(NSString*)funcion{
    //[self f01modindicadormasmenosgraficaconfig:@"GRisk" rana:.99 ranb:1.05 gra:riesgo config:@"%.02f"];
    //[self f01modindicadormasmenosgraficaconfig:@"GQuality" rana:.99 ranb:1.05 gra:calidad config:@"%.02f"];
    if ([funcion isEqualToString:@"Planning"]) {
        //Actualizacion del Indicador
        
        float pos=[self f02modindicadormasmenosconfigfloat:@"Planning" rana:0.00 ranb:0.03 config:@"%.02f"];
        NSLog(@"Indicador positivo %f",pos);
        float pos1=((pos-1)*.60)+1;
        NSLog(@"Indicador segundo %f",pos1);
        float neg=(2-pos);
        NSLog(@"Indicador NEG%f",neg);
        float neg2=((1-neg)*.5)+neg;
        NSLog(@"Indicador NEG2%f",neg2);
        //Inicio Tareas
        
        [self f09modreccamfaccon:RR1 Campo:@"Start" factor:neg config:@"%.02f"];
        [self f09modreccamfaccon:RR2 Campo:@"Start" factor:neg config:@"%.02f"];
        [self f09modreccamfaccon:RR3 Campo:@"Start" factor:neg config:@"%.02f"];
        [self f09modreccamfaccon:RR4 Campo:@"Start" factor:neg config:@"%.02f"];
        [self f09modreccamfaccon:RR5 Campo:@"Start" factor:neg config:@"%.02f"];
        [self f09modreccamfaccon:RR6 Campo:@"Start" factor:neg config:@"%.02f"];
        
        [self f08modpotcamfaccon:RP1 Campo:@"Start" factor:neg config:@"%.02f"];
        [self f08modpotcamfaccon:RP2 Campo:@"Start" factor:neg config:@"%.02f"];
        [self f08modpotcamfaccon:RP3 Campo:@"Start" factor:neg config:@"%.02f"];
        [self f08modpotcamfaccon:RP4 Campo:@"Start" factor:neg config:@"%.02f"];
        [self f08modpotcamfaccon:RP5 Campo:@"Start" factor:neg config:@"%.02f"];
        [self f08modpotcamfaccon:RP6 Campo:@"Start" factor:neg config:@"%.02f"];

        //Rendimiento Local
        [self f10modreccametifacconf:RR1 Campo:@"Rendimiento" etiqueta:RR1.LRendimiento factor:pos config:@"%.02f"];
        [self f10modreccametifacconf:RR2 Campo:@"Rendimiento" etiqueta:RR2.LRendimiento factor:pos config:@"%.02f"];
        [self f10modreccametifacconf:RR3 Campo:@"Rendimiento" etiqueta:RR3.LRendimiento factor:pos config:@"%.02f"];
        [self f10modreccametifacconf:RR4 Campo:@"Rendimiento" etiqueta:RR4.LRendimiento factor:pos config:@"%.02f"];
        [self f10modreccametifacconf:RR5 Campo:@"Rendimiento" etiqueta:RR5.LRendimiento factor:pos config:@"%.02f"];
        [self f10modreccametifacconf:RR6 Campo:@"Rendimiento" etiqueta:RR6.LRendimiento factor:pos config:@"%.02f"];
        
        //Rendimiento Acumulado
        [self f04modreccamfaccon:RR1 Campo:@"RendimientoAcumulado" factor:pos config:@"%.02f"];
        [self f04modreccamfaccon:RR2 Campo:@"RendimientoAcumulado" factor:pos config:@"%.02f"];
        [self f04modreccamfaccon:RR3 Campo:@"RendimientoAcumulado" factor:pos config:@"%.02f"];
        [self f04modreccamfaccon:RR4 Campo:@"RendimientoAcumulado" factor:pos config:@"%.02f"];
        [self f04modreccamfaccon:RR5 Campo:@"RendimientoAcumulado" factor:pos config:@"%.02f"];
        [self f04modreccamfaccon:RR6 Campo:@"RendimientoAcumulado" factor:pos config:@"%.02f"];
        
        //Adicionales
        [self f05modindicadorcamfacgracon:@"GQuality" factor:pos gra:calidad config:@"%f"];
        [self f05modindicadorcamfacgracon:@"GRisk" factor:pos gra:riesgo config:@"%f"];
        
        [self f06modcamfacconf:@"Comunications" factor:pos1 config:@"%f"];
        [self f06modcamfacconf:@"Quality" factor:pos1 config:@"%f"];
        
    }
    if ([funcion isEqualToString:@"Procurement"]) {
        //Actualizacion del Indicador
        float pos=[self f02modindicadormasmenosconfigfloat:@"Procurement" rana:0.00 ranb:0.03 config:@"%.02f"];
        NSLog(@"Indicador  %f",pos);
        float pos1=((pos-1)*.60)+1;
        NSLog(@"Indicador segundo %f",pos1);
        float neg=(2-pos);
        NSLog(@"Indicador NEG%f",neg);
        float neg2=((1-neg)*.5)+neg;
        NSLog(@"Indicador NEG2%f",neg2);
        //Rendimiento Local
        
        [self f10modreccametifacconf:RR1 Campo:@"Costo" etiqueta:RR1.LCosto factor:neg config:@"%.02f"];
        [self f10modreccametifacconf:RR2 Campo:@"Costo" etiqueta:RR2.LCosto factor:neg config:@"%.02f"];
        [self f10modreccametifacconf:RR3 Campo:@"Costo" etiqueta:RR3.LCosto factor:neg config:@"%.02f"];
        [self f10modreccametifacconf:RR4 Campo:@"Costo" etiqueta:RR4.LCosto factor:neg config:@"%.02f"];
        [self f10modreccametifacconf:RR5 Campo:@"Costo" etiqueta:RR5.LCosto factor:neg config:@"%.02f"];
        [self f10modreccametifacconf:RR6 Campo:@"Costo" etiqueta:RR6.LCosto factor:neg config:@"%.02f"];
        
        [self f11modreccametifacconf:RP1 Campo:@"Costo" etiqueta:RP1.LCosto factor:neg config:@"%.02f"];
        [self f11modreccametifacconf:RP2 Campo:@"Costo" etiqueta:RP2.LCosto factor:neg config:@"%.02f"];
        [self f11modreccametifacconf:RP3 Campo:@"Costo" etiqueta:RP3.LCosto factor:neg config:@"%.02f"];
        [self f11modreccametifacconf:RP4 Campo:@"Costo" etiqueta:RP4.LCosto factor:neg config:@"%.02f"];
        [self f11modreccametifacconf:RP5 Campo:@"Costo" etiqueta:RP5.LCosto factor:neg config:@"%.02f"];
        [self f11modreccametifacconf:RP6 Campo:@"Costo" etiqueta:RP6.LCosto factor:neg config:@"%.02f"];
        
        //Adicionales
        
        [self f06modcamfacconf:@"Planning" factor:pos1  config:@"%f"];
        [self f06modcamfacconf:@"Risk" factor:pos1 config:@"%f"];

        
        NSLog(@"Procurement");
    }
    if ([funcion isEqualToString:@"Risk"]) {
        //Actualizacion del Indicador
        float pos=[self f02modindicadormasmenosconfigfloat:@"Risk" rana:0.00 ranb:0.03 config:@"%.02f"];
        NSLog(@"Indicador  %f",pos);
        float pos1=((pos-1)*.60)+1;
        NSLog(@"Indicador segundo %f",pos1);
        float neg=(2-pos);
        NSLog(@"Indicador NEG%f",neg);
        float neg2=((1-neg)*.5)+neg;
        NSLog(@"Indicador NEG2%f",neg2);
        //Rendimiento Local
        [self f03modreccametifacconf:RR1 Campo:@"Costo" etiqueta:RR1.LCosto factor:pos1 config:@"%.02f"];
        [self f03modreccametifacconf:RR2 Campo:@"Costo" etiqueta:RR2.LCosto factor:pos1 config:@"%.02f"];
        [self f03modreccametifacconf:RR3 Campo:@"Costo" etiqueta:RR3.LCosto factor:pos1 config:@"%.02f"];
        [self f03modreccametifacconf:RR4 Campo:@"Costo" etiqueta:RR4.LCosto factor:pos1 config:@"%.02f"];
        [self f03modreccametifacconf:RR5 Campo:@"Costo" etiqueta:RR5.LCosto factor:pos1 config:@"%.02f"];
        [self f03modreccametifacconf:RR6 Campo:@"Costo" etiqueta:RR6.LCosto factor:pos1 config:@"%.02f"];
        
        [self f07modpotcametifacconf:RP1 Campo:@"Costo" etiqueta:RP1.LCosto factor:pos1 config:@"%.02f"];
        [self f07modpotcametifacconf:RP2 Campo:@"Costo" etiqueta:RP2.LCosto factor:pos1 config:@"%.02f"];
        [self f07modpotcametifacconf:RP3 Campo:@"Costo" etiqueta:RP3.LCosto factor:pos1 config:@"%.02f"];
        [self f07modpotcametifacconf:RP4 Campo:@"Costo" etiqueta:RP4.LCosto factor:pos1 config:@"%.02f"];
        [self f07modpotcametifacconf:RP5 Campo:@"Costo" etiqueta:RP5.LCosto factor:pos1 config:@"%.02f"];
        [self f07modpotcametifacconf:RP6 Campo:@"Costo" etiqueta:RP6.LCosto factor:pos1 config:@"%.02f"];
        //Adicionales
        [self f03modreccametifacconf:RR1 Campo:@"Rendimiento" etiqueta:RR1.LRendimiento factor:neg config:@"%.02f"];
        [self f03modreccametifacconf:RR2 Campo:@"Rendimiento" etiqueta:RR2.LRendimiento factor:neg config:@"%.02f"];
        [self f03modreccametifacconf:RR3 Campo:@"Rendimiento" etiqueta:RR3.LRendimiento factor:neg config:@"%.02f"];
        [self f03modreccametifacconf:RR4 Campo:@"Rendimiento" etiqueta:RR4.LRendimiento factor:neg config:@"%.02f"];
        [self f03modreccametifacconf:RR5 Campo:@"Rendimiento" etiqueta:RR5.LRendimiento factor:neg config:@"%.02f"];
        [self f03modreccametifacconf:RR6 Campo:@"Rendimiento" etiqueta:RR6.LRendimiento factor:neg config:@"%.02f"];
        
        [self f05modindicadorcamfacgracon:@"GQuality" factor:pos gra:calidad config:@"%f"];
        [self f05modindicadorcamfacgracon:@"GRisk" factor:pos gra:riesgo config:@"%f"];
        
        [self f06modcamfacconf:@"Planning" factor:pos1  config:@"%f"];
        [self f06modcamfacconf:@"Communications" factor:pos1 config:@"%f"];
       

        NSLog(@"Risk");

    }
    if ([funcion isEqualToString:@"Communications"]) {
        float pos=[self f02modindicadormasmenosconfigfloat:@"Communications" rana:0.00 ranb:0.03 config:@"%.02f"];
        NSLog(@"Indicador  %f",pos);
        float pos1=((pos-1)*.60)+1;
        NSLog(@"Indicador segundo %f",pos1);
        float neg=(2-pos);
        NSLog(@"Indicador NEG%f",neg);
        float neg2=((1-neg)*.5)+neg;
        NSLog(@"Indicador NEG2%f",neg2);
        
        [self f03modreccametifacconf:RR1 Campo:@"Rendimiento" etiqueta:RR1.LRendimiento factor:pos1 config:@"%.02f"];
        [self f03modreccametifacconf:RR2 Campo:@"Rendimiento" etiqueta:RR2.LRendimiento factor:pos1 config:@"%.02f"];
        [self f03modreccametifacconf:RR3 Campo:@"Rendimiento" etiqueta:RR3.LRendimiento factor:pos1 config:@"%.02f"];
        [self f03modreccametifacconf:RR4 Campo:@"Rendimiento" etiqueta:RR4.LRendimiento factor:pos1 config:@"%.02f"];
        [self f03modreccametifacconf:RR5 Campo:@"Rendimiento" etiqueta:RR5.LRendimiento factor:pos1 config:@"%.02f"];
        [self f03modreccametifacconf:RR6 Campo:@"Rendimiento" etiqueta:RR6.LRendimiento factor:pos1 config:@"%.02f"];
        
        [self f04modreccamfaccon:RR1 Campo:@"RendimientoAcumulado" factor:pos config:@"%.02f"];
        [self f04modreccamfaccon:RR2 Campo:@"RendimientoAcumulado" factor:pos config:@"%.02f"];
        [self f04modreccamfaccon:RR3 Campo:@"RendimientoAcumulado" factor:pos config:@"%.02f"];
        [self f04modreccamfaccon:RR4 Campo:@"RendimientoAcumulado" factor:pos config:@"%.02f"];
        [self f04modreccamfaccon:RR5 Campo:@"RendimientoAcumulado" factor:pos config:@"%.02f"];
        [self f04modreccamfaccon:RR6 Campo:@"RendimientoAcumulado" factor:pos config:@"%.02f"];


        [self f06modcamfacconf:@"Procurement" factor:pos1 config:@"%f"];
        [self f06modcamfacconf:@"Training" factor:pos1 config:@"%f"];
        
         NSLog(@"Comunications");
        
    }
    if ([funcion isEqualToString:@"Training"]) {
        float pos=[self f02modindicadormasmenosconfigfloat:@"Training" rana:0.00 ranb:0.03 config:@"%.02f"];
        NSLog(@"Indicador  %f",pos);
        float pos1=((pos-1)*.60)+1;
        NSLog(@"Indicador segundo %f",pos1);
        float neg=(2-pos);
        NSLog(@"Indicador NEG%f",neg);
        float neg2=((1-neg)*.5)+neg;
        NSLog(@"Indicador NEG2%f",neg2);
        
        [self f04modreccamfaccon:RR1 Campo:@"RendimientoAcumulado" factor:pos config:@"%.02f"];
        [self f04modreccamfaccon:RR2 Campo:@"RendimientoAcumulado" factor:pos config:@"%.02f"];
        [self f04modreccamfaccon:RR3 Campo:@"RendimientoAcumulado" factor:pos config:@"%.02f"];
        [self f04modreccamfaccon:RR4 Campo:@"RendimientoAcumulado" factor:pos config:@"%.02f"];
        [self f04modreccamfaccon:RR5 Campo:@"RendimientoAcumulado" factor:pos config:@"%.02f"];
        [self f04modreccamfaccon:RR6 Campo:@"RendimientoAcumulado" factor:pos config:@"%.02f"];
        
        [self f03modreccametifacconf:RR1 Campo:@"Costo" etiqueta:RR1.LCosto factor:neg config:@"%.02f"];
        [self f03modreccametifacconf:RR2 Campo:@"Costo" etiqueta:RR2.LCosto factor:neg config:@"%.02f"];
        [self f03modreccametifacconf:RR3 Campo:@"Costo" etiqueta:RR3.LCosto factor:neg config:@"%.02f"];
        [self f03modreccametifacconf:RR4 Campo:@"Costo" etiqueta:RR4.LCosto factor:neg config:@"%.02f"];
        [self f03modreccametifacconf:RR5 Campo:@"Costo" etiqueta:RR5.LCosto factor:neg config:@"%.02f"];
        [self f03modreccametifacconf:RR6 Campo:@"Costo" etiqueta:RR6.LCosto factor:neg config:@"%.02f"];
        
        [self f07modpotcametifacconf:RP1 Campo:@"Costo" etiqueta:RP1.LCosto factor:neg config:@"%.02f"];
        [self f07modpotcametifacconf:RP2 Campo:@"Costo" etiqueta:RP2.LCosto factor:neg config:@"%.02f"];
        [self f07modpotcametifacconf:RP3 Campo:@"Costo" etiqueta:RP3.LCosto factor:neg config:@"%.02f"];
        [self f07modpotcametifacconf:RP4 Campo:@"Costo" etiqueta:RP4.LCosto factor:neg config:@"%.02f"];
        [self f07modpotcametifacconf:RP5 Campo:@"Costo" etiqueta:RP5.LCosto factor:neg config:@"%.02f"];
        [self f07modpotcametifacconf:RP6 Campo:@"Costo" etiqueta:RP6.LCosto factor:neg config:@"%.02f"];
        
        [self f05modindicadorcamfacgracon:@"GQuality" factor:pos1 gra:calidad config:@"%f"];
        [self f05modindicadorcamfacgracon:@"GRisk" factor:pos1 gra:riesgo config:@"%f"];
        
  
        [self f06modcamfacconf:@"Quality" factor:pos1 config:@"%f"];
        [self f06modcamfacconf:@"Risk" factor:pos1 config:@"%f"];
        
        NSLog(@"Training");
        
    }
    if ([funcion isEqualToString:@"Quality"]) {
        //Actualizacion del Indicador
        float pos=[self f02modindicadormasmenosconfigfloat:@"Quality" rana:0.00 ranb:0.03 config:@"%.02f"];
        NSLog(@"Indicador  %f",pos);
        float pos1=((pos-1)*.60)+1;
        NSLog(@"Indicador segundo %f",pos1);
        float neg=(2-pos);
        NSLog(@"Indicador NEG%f",neg);
        float neg2=((1-neg)*.5)+neg;
        NSLog(@"Indicador NEG2%f",neg2);
        //Rendimiento Local
        [self f03modreccametifacconf:RR1 Campo:@"Costo" etiqueta:RR1.LCosto factor:pos1 config:@"%.02f"];
        [self f03modreccametifacconf:RR2 Campo:@"Costo" etiqueta:RR2.LCosto factor:pos1 config:@"%.02f"];
        [self f03modreccametifacconf:RR3 Campo:@"Costo" etiqueta:RR3.LCosto factor:pos1 config:@"%.02f"];
        [self f03modreccametifacconf:RR4 Campo:@"Costo" etiqueta:RR4.LCosto factor:pos1 config:@"%.02f"];
        [self f03modreccametifacconf:RR5 Campo:@"Costo" etiqueta:RR5.LCosto factor:pos1 config:@"%.02f"];
        [self f03modreccametifacconf:RR6 Campo:@"Costo" etiqueta:RR6.LCosto factor:pos1 config:@"%.02f"];
        
        [self f07modpotcametifacconf:RP1 Campo:@"Costo" etiqueta:RP1.LCosto factor:pos1 config:@"%.02f"];
        [self f07modpotcametifacconf:RP2 Campo:@"Costo" etiqueta:RP2.LCosto factor:pos1 config:@"%.02f"];
        [self f07modpotcametifacconf:RP3 Campo:@"Costo" etiqueta:RP3.LCosto factor:pos1 config:@"%.02f"];
        [self f07modpotcametifacconf:RP4 Campo:@"Costo" etiqueta:RP4.LCosto factor:pos1 config:@"%.02f"];
        [self f07modpotcametifacconf:RP5 Campo:@"Costo" etiqueta:RP5.LCosto factor:pos1 config:@"%.02f"];
        [self f07modpotcametifacconf:RP6 Campo:@"Costo" etiqueta:RP6.LCosto factor:pos1 config:@"%.02f"];
        
        [self f03modreccametifacconf:RR1 Campo:@"Rendimiento" etiqueta:RR1.LRendimiento factor:pos config:@"%.02f"];
        [self f03modreccametifacconf:RR2 Campo:@"Rendimiento" etiqueta:RR2.LRendimiento factor:pos config:@"%.02f"];
        [self f03modreccametifacconf:RR3 Campo:@"Rendimiento" etiqueta:RR3.LRendimiento factor:pos config:@"%.02f"];
        [self f03modreccametifacconf:RR4 Campo:@"Rendimiento" etiqueta:RR4.LRendimiento factor:pos config:@"%.02f"];
        [self f03modreccametifacconf:RR5 Campo:@"Rendimiento" etiqueta:RR5.LRendimiento factor:pos config:@"%.02f"];
        [self f03modreccametifacconf:RR6 Campo:@"Rendimiento" etiqueta:RR6.LRendimiento factor:pos config:@"%.02f"];
        
        //Adicionales
        
        [self f05modindicadorcamfacgracon:@"GQuality" factor:pos1 gra:calidad config:@"%f"];
        [self f05modindicadorcamfacgracon:@"GRisk" factor:pos1 gra:riesgo config:@"%f"];
        
        [self f06modcamfacconf:@"Training" factor:pos1 config:@"%f"];
        [self f06modcamfacconf:@"Procurement" factor:pos1 config:@"%f"];
        


        NSLog(@"Quality");
    }
    
}
-(void)RMINUSA:(NSString*)funcion{
    [self f01modindicadormasmenosgraficaconfig:@"GRisk" rana:0.95 ranb:1.01 gra:riesgo config:@"%.02f"];
    [self f01modindicadormasmenosgraficaconfig:@"GQuality" rana:0.95 ranb:1.01 gra:calidad config:@"%.02f"];
    if ([funcion isEqualToString:@"Planning"]) {
        //Actualizacion del Indicador
        
        float pos=[self f02modindicadormasmenosconfigfloat:@"Planning" rana:-0.00 ranb:-0.02 config:@"%.02f"];
        NSLog(@"Indicador POS %f",pos);
        float neg=(2-pos);
        NSLog(@"Indicador NEG%f",neg);
        float neg2=((1-neg)*.5)+neg;
        NSLog(@"Indicador NEG2%f",neg2);
        //Inicio Tareas
        
        [self f09modreccamfaccon:RR1 Campo:@"Start" factor:pos config:@"%.02f"];
        [self f09modreccamfaccon:RR2 Campo:@"Start" factor:pos config:@"%.02f"];
        [self f09modreccamfaccon:RR3 Campo:@"Start" factor:pos config:@"%.02f"];
        [self f09modreccamfaccon:RR4 Campo:@"Start" factor:pos config:@"%.02f"];
        [self f09modreccamfaccon:RR5 Campo:@"Start" factor:pos config:@"%.02f"];
        [self f09modreccamfaccon:RR6 Campo:@"Start" factor:pos config:@"%.02f"];
        
        [self f08modpotcamfaccon:RP1 Campo:@"Start" factor:pos config:@"%.02f"];
        [self f08modpotcamfaccon:RP2 Campo:@"Start" factor:pos config:@"%.02f"];
        [self f08modpotcamfaccon:RP3 Campo:@"Start" factor:pos config:@"%.02f"];
        [self f08modpotcamfaccon:RP4 Campo:@"Start" factor:pos config:@"%.02f"];
        [self f08modpotcamfaccon:RP5 Campo:@"Start" factor:pos config:@"%.02f"];
        [self f08modpotcamfaccon:RP6 Campo:@"Start" factor:pos config:@"%.02f"];
        
        //Rendimiento Local
        [self f10modreccametifacconf:RR1 Campo:@"Rendimiento" etiqueta:RR1.LRendimiento factor:neg config:@"%.02f"];
        [self f10modreccametifacconf:RR2 Campo:@"Rendimiento" etiqueta:RR2.LRendimiento factor:neg config:@"%.02f"];
        [self f10modreccametifacconf:RR3 Campo:@"Rendimiento" etiqueta:RR3.LRendimiento factor:neg config:@"%.02f"];
        [self f10modreccametifacconf:RR4 Campo:@"Rendimiento" etiqueta:RR4.LRendimiento factor:neg config:@"%.02f"];
        [self f10modreccametifacconf:RR5 Campo:@"Rendimiento" etiqueta:RR5.LRendimiento factor:neg config:@"%.02f"];
        [self f10modreccametifacconf:RR6 Campo:@"Rendimiento" etiqueta:RR6.LRendimiento factor:neg config:@"%.02f"];
        //Rendimiento Acumulado
        [self f04modreccamfaccon:RR1 Campo:@"RendimientoAcumulado" factor:neg config:@"%.02f"];
        [self f04modreccamfaccon:RR2 Campo:@"RendimientoAcumulado" factor:neg config:@"%.02f"];
        [self f04modreccamfaccon:RR3 Campo:@"RendimientoAcumulado" factor:neg config:@"%.02f"];
        [self f04modreccamfaccon:RR4 Campo:@"RendimientoAcumulado" factor:neg config:@"%.02f"];
        [self f04modreccamfaccon:RR5 Campo:@"RendimientoAcumulado" factor:neg config:@"%.02f"];
        [self f04modreccamfaccon:RR6 Campo:@"RendimientoAcumulado" factor:neg config:@"%.02f"];
        
        //Adicionales
        [self f05modindicadorcamfacgracon:@"GQuality" factor:neg2 gra:calidad config:@"%f"];
        [self f05modindicadorcamfacgracon:@"GRisk" factor:neg2 gra:riesgo config:@"%f"];
        
        [self f06modcamfacconf:@"Communications" factor:pos config:@"%f"];
        [self f06modcamfacconf:@"Quality" factor:pos config:@"%f"];
        
    }
    if ([funcion isEqualToString:@"Procurement"]) {
        //Actualizacion del Indicador
        float pos=[self f02modindicadormasmenosconfigfloat:@"Procurement" rana:-0.00 ranb:-0.02 config:@"%.02f"];
        NSLog(@"Indicador  %f",pos);
        float pos1=((pos-1)*.60)+1;
        NSLog(@"Indicador segundo %f",pos1);
        float neg=(2-pos);
        NSLog(@"Indicador NEG%f",neg);
        float neg2=((1-neg)*.5)+neg;
        NSLog(@"Indicador NEG2%f",neg2);
        //Rendimiento Local
        [self f10modreccametifacconf:RR1 Campo:@"Costo" etiqueta:RR1.LCosto factor:pos config:@"%.02f"];
        [self f10modreccametifacconf:RR2 Campo:@"Costo" etiqueta:RR2.LCosto factor:pos config:@"%.02f"];
        [self f10modreccametifacconf:RR3 Campo:@"Costo" etiqueta:RR3.LCosto factor:pos config:@"%.02f"];
        [self f10modreccametifacconf:RR4 Campo:@"Costo" etiqueta:RR4.LCosto factor:pos config:@"%.02f"];
        [self f10modreccametifacconf:RR5 Campo:@"Costo" etiqueta:RR5.LCosto factor:pos config:@"%.02f"];
        [self f10modreccametifacconf:RR6 Campo:@"Costo" etiqueta:RR6.LCosto factor:pos config:@"%.02f"];
        
        [self f11modreccametifacconf:RP1 Campo:@"Costo" etiqueta:RP1.LCosto factor:pos config:@"%.02f"];
        [self f11modreccametifacconf:RP2 Campo:@"Costo" etiqueta:RP2.LCosto factor:pos config:@"%.02f"];
        [self f11modreccametifacconf:RP3 Campo:@"Costo" etiqueta:RP3.LCosto factor:pos config:@"%.02f"];
        [self f11modreccametifacconf:RP4 Campo:@"Costo" etiqueta:RP4.LCosto factor:pos config:@"%.02f"];
        [self f11modreccametifacconf:RP5 Campo:@"Costo" etiqueta:RP5.LCosto factor:pos config:@"%.02f"];
        [self f11modreccametifacconf:RP6 Campo:@"Costo" etiqueta:RP6.LCosto factor:pos config:@"%.02f"];
        
        //Adicionales
        //[self f05modindicadorcamfacgracon:@"GQuality" factor:neg2 gra:calidad config:@"%f"];
        //[self f05modindicadorcamfacgracon:@"GRisk" factor:neg2 gra:riesgo config:@"%f"];
        
        [self f06modcamfacconf:@"Planning" factor:pos1  config:@"%f"];
        [self f06modcamfacconf:@"Risk" factor:pos1 config:@"%f"];
        
        NSLog(@"Procurement");
    }
    if ([funcion isEqualToString:@"Risk"]) {
        //Actualizacion del Indicador
        float pos=[self f02modindicadormasmenosconfigfloat:@"Risk" rana:-0.00 ranb:-0.02 config:@"%.02f"];
        NSLog(@"Indicador  %f",pos);
        float pos1=((pos-1)*.60)+1;
        NSLog(@"Indicador segundo %f",pos1);
        float neg=(2-pos);
        NSLog(@"Indicador NEG%f",neg);
        float neg2=((1-neg)*.5)+neg;
        NSLog(@"Indicador NEG2%f",neg2);
        //Rendimiento Local
        [self f03modreccametifacconf:RR1 Campo:@"Costo" etiqueta:RR1.LCosto factor:neg2 config:@"%.02f"];
        [self f03modreccametifacconf:RR2 Campo:@"Costo" etiqueta:RR2.LCosto factor:neg2 config:@"%.02f"];
        [self f03modreccametifacconf:RR3 Campo:@"Costo" etiqueta:RR3.LCosto factor:neg2 config:@"%.02f"];
        [self f03modreccametifacconf:RR4 Campo:@"Costo" etiqueta:RR4.LCosto factor:neg2 config:@"%.02f"];
        [self f03modreccametifacconf:RR5 Campo:@"Costo" etiqueta:RR5.LCosto factor:neg2 config:@"%.02f"];
        [self f03modreccametifacconf:RR6 Campo:@"Costo" etiqueta:RR6.LCosto factor:neg2 config:@"%.02f"];
        
        [self f07modpotcametifacconf:RP1 Campo:@"Costo" etiqueta:RP1.LCosto factor:neg2 config:@"%.02f"];
        [self f07modpotcametifacconf:RP2 Campo:@"Costo" etiqueta:RP2.LCosto factor:neg2 config:@"%.02f"];
        [self f07modpotcametifacconf:RP3 Campo:@"Costo" etiqueta:RP3.LCosto factor:neg2 config:@"%.02f"];
        [self f07modpotcametifacconf:RP4 Campo:@"Costo" etiqueta:RP4.LCosto factor:neg2 config:@"%.02f"];
        [self f07modpotcametifacconf:RP5 Campo:@"Costo" etiqueta:RP5.LCosto factor:neg2 config:@"%.02f"];
        [self f07modpotcametifacconf:RP6 Campo:@"Costo" etiqueta:RP6.LCosto factor:neg2 config:@"%.02f"];
        
        //Adicionales
        [self f03modreccametifacconf:RR1 Campo:@"Rendimiento" etiqueta:RR1.LRendimiento factor:pos config:@"%.02f"];
        [self f03modreccametifacconf:RR2 Campo:@"Rendimiento" etiqueta:RR2.LRendimiento factor:pos config:@"%.02f"];
        [self f03modreccametifacconf:RR3 Campo:@"Rendimiento" etiqueta:RR3.LRendimiento factor:pos config:@"%.02f"];
        [self f03modreccametifacconf:RR4 Campo:@"Rendimiento" etiqueta:RR4.LRendimiento factor:pos config:@"%.02f"];
        [self f03modreccametifacconf:RR5 Campo:@"Rendimiento" etiqueta:RR5.LRendimiento factor:pos config:@"%.02f"];
        [self f03modreccametifacconf:RR6 Campo:@"Rendimiento" etiqueta:RR6.LRendimiento factor:pos config:@"%.02f"];
        
        [self f05modindicadorcamfacgracon:@"GQuality" factor:neg gra:calidad config:@"%f"];
        [self f05modindicadorcamfacgracon:@"GRisk" factor:neg gra:riesgo config:@"%f"];
        
        [self f06modcamfacconf:@"Planning" factor:pos1  config:@"%f"];
        [self f06modcamfacconf:@"Communications" factor:pos1 config:@"%f"];
        
        NSLog(@"Risk");
        
    }
    if ([funcion isEqualToString:@"Communications"]) {
        //Actualizacion del Indicador
        float pos=[self f02modindicadormasmenosconfigfloat:@"Risk" rana:-0.00 ranb:-0.02 config:@"%.02f"];
        NSLog(@"Indicador  %f",pos);
        float pos1=((pos-1)*.60)+1;
        NSLog(@"Indicador segundo %f",pos1);
        float neg=(2-pos);
        NSLog(@"Indicador NEG%f",neg);
        float neg2=((1-neg)*.5)+neg;
        NSLog(@"Indicador NEG2%f",neg2);
        
        [self f03modreccametifacconf:RR1 Campo:@"Rendimiento" etiqueta:RR1.LRendimiento factor:neg2 config:@"%.02f"];
        [self f03modreccametifacconf:RR2 Campo:@"Rendimiento" etiqueta:RR2.LRendimiento factor:neg2 config:@"%.02f"];
        [self f03modreccametifacconf:RR3 Campo:@"Rendimiento" etiqueta:RR3.LRendimiento factor:neg2 config:@"%.02f"];
        [self f03modreccametifacconf:RR4 Campo:@"Rendimiento" etiqueta:RR4.LRendimiento factor:neg2 config:@"%.02f"];
        [self f03modreccametifacconf:RR5 Campo:@"Rendimiento" etiqueta:RR5.LRendimiento factor:neg2 config:@"%.02f"];
        [self f03modreccametifacconf:RR6 Campo:@"Rendimiento" etiqueta:RR6.LRendimiento factor:neg2 config:@"%.02f"];
        
        [self f04modreccamfaccon:RR1 Campo:@"RendimientoAcumulado" factor:neg config:@"%.02f"];
        [self f04modreccamfaccon:RR2 Campo:@"RendimientoAcumulado" factor:neg config:@"%.02f"];
        [self f04modreccamfaccon:RR3 Campo:@"RendimientoAcumulado" factor:neg config:@"%.02f"];
        [self f04modreccamfaccon:RR4 Campo:@"RendimientoAcumulado" factor:neg config:@"%.02f"];
        [self f04modreccamfaccon:RR5 Campo:@"RendimientoAcumulado" factor:neg config:@"%.02f"];
        [self f04modreccamfaccon:RR6 Campo:@"RendimientoAcumulado" factor:neg config:@"%.02f"];
        
        [self f06modcamfacconf:@"Procurement" factor:pos config:@"%f"];
        [self f06modcamfacconf:@"Training" factor:pos config:@"%f"];
        
        
        NSLog(@"Comunications");
    }
      
    if ([funcion isEqualToString:@"Training"]) {
        float pos=[self f02modindicadormasmenosconfigfloat:@"Training" rana:-0.00 ranb:-0.02 config:@"%.02f"];
        NSLog(@"Indicador  %f",pos);
        float pos1=((pos-1)*.60)+1;
        NSLog(@"Indicador segundo %f",pos1);
        float neg=(2-pos);
        NSLog(@"Indicador NEG%f",neg);
        float neg2=((1-neg)*.5)+neg;
        NSLog(@"Indicador NEG2%f",neg2);
        
        [self f04modreccamfaccon:RR1 Campo:@"RendimientoAcumulado" factor:neg config:@"%.02f"];
        [self f04modreccamfaccon:RR2 Campo:@"RendimientoAcumulado" factor:neg config:@"%.02f"];
        [self f04modreccamfaccon:RR3 Campo:@"RendimientoAcumulado" factor:neg config:@"%.02f"];
        [self f04modreccamfaccon:RR4 Campo:@"RendimientoAcumulado" factor:neg config:@"%.02f"];
        [self f04modreccamfaccon:RR5 Campo:@"RendimientoAcumulado" factor:neg config:@"%.02f"];
        [self f04modreccamfaccon:RR6 Campo:@"RendimientoAcumulado" factor:neg config:@"%.02f"];
        
        [self f03modreccametifacconf:RR1 Campo:@"Costo" etiqueta:RR1.LCosto factor:pos1 config:@"%.02f"];
        [self f03modreccametifacconf:RR2 Campo:@"Costo" etiqueta:RR2.LCosto factor:pos1 config:@"%.02f"];
        [self f03modreccametifacconf:RR3 Campo:@"Costo" etiqueta:RR3.LCosto factor:pos1 config:@"%.02f"];
        [self f03modreccametifacconf:RR4 Campo:@"Costo" etiqueta:RR4.LCosto factor:pos1 config:@"%.02f"];
        [self f03modreccametifacconf:RR5 Campo:@"Costo" etiqueta:RR5.LCosto factor:pos1 config:@"%.02f"];
        [self f03modreccametifacconf:RR6 Campo:@"Costo" etiqueta:RR6.LCosto factor:pos1 config:@"%.02f"];
        
        [self f07modpotcametifacconf:RP1 Campo:@"Costo" etiqueta:RP1.LCosto factor:pos1 config:@"%.02f"];
        [self f07modpotcametifacconf:RP2 Campo:@"Costo" etiqueta:RP2.LCosto factor:pos1 config:@"%.02f"];
        [self f07modpotcametifacconf:RP3 Campo:@"Costo" etiqueta:RP3.LCosto factor:pos1 config:@"%.02f"];
        [self f07modpotcametifacconf:RP4 Campo:@"Costo" etiqueta:RP4.LCosto factor:pos1 config:@"%.02f"];
        [self f07modpotcametifacconf:RP5 Campo:@"Costo" etiqueta:RP5.LCosto factor:pos1 config:@"%.02f"];
        [self f07modpotcametifacconf:RP6 Campo:@"Costo" etiqueta:RP6.LCosto factor:pos1 config:@"%.02f"];
        
                [self f05modindicadorcamfacgracon:@"GQuality" factor:neg2 gra:calidad config:@"%f"];
        [self f05modindicadorcamfacgracon:@"GRisk" factor:neg2 gra:riesgo config:@"%f"];
        
        [self f06modcamfacconf:@"Quality" factor:pos1 config:@"%f"];
        [self f06modcamfacconf:@"Risk" factor:pos1 config:@"%f"];
        
        NSLog(@"Training");
        
    }
    if ([funcion isEqualToString:@"Quality"]) {
        //Actualizacion del Indicador
        float pos=[self f02modindicadormasmenosconfigfloat:@"Quality" rana:-0.00 ranb:-0.02 config:@"%.02f"];
        NSLog(@"Indicador  %f",pos);
        float pos1=((pos-1)*.60)+1;
        NSLog(@"Indicador segundo %f",pos1);
        float neg=(2-pos);
        NSLog(@"Indicador NEG%f",neg);
        float neg2=((1-neg)*.5)+neg;
        NSLog(@"Indicador NEG2%f",neg2);
        //Rendimiento Local
        [self f03modreccametifacconf:RR1 Campo:@"Costo" etiqueta:RR1.LCosto factor:neg2 config:@"%.02f"];
        [self f03modreccametifacconf:RR2 Campo:@"Costo" etiqueta:RR2.LCosto factor:neg2 config:@"%.02f"];
        [self f03modreccametifacconf:RR3 Campo:@"Costo" etiqueta:RR3.LCosto factor:neg2 config:@"%.02f"];
        [self f03modreccametifacconf:RR4 Campo:@"Costo" etiqueta:RR4.LCosto factor:neg2 config:@"%.02f"];
        [self f03modreccametifacconf:RR5 Campo:@"Costo" etiqueta:RR5.LCosto factor:neg2 config:@"%.02f"];
        [self f03modreccametifacconf:RR6 Campo:@"Costo" etiqueta:RR6.LCosto factor:neg2 config:@"%.02f"];
        
        [self f07modpotcametifacconf:RP1 Campo:@"Costo" etiqueta:RP1.LCosto factor:neg2 config:@"%.02f"];
        [self f07modpotcametifacconf:RP2 Campo:@"Costo" etiqueta:RP2.LCosto factor:neg2 config:@"%.02f"];
        [self f07modpotcametifacconf:RP3 Campo:@"Costo" etiqueta:RP3.LCosto factor:neg2 config:@"%.02f"];
        [self f07modpotcametifacconf:RP4 Campo:@"Costo" etiqueta:RP4.LCosto factor:neg2 config:@"%.02f"];
        [self f07modpotcametifacconf:RP5 Campo:@"Costo" etiqueta:RP5.LCosto factor:neg2 config:@"%.02f"];
        [self f07modpotcametifacconf:RP6 Campo:@"Costo" etiqueta:RP6.LCosto factor:neg2 config:@"%.02f"];
        
        //Adicionales

        [self f03modreccametifacconf:RR1 Campo:@"Rendimiento" etiqueta:RR1.LRendimiento factor:neg config:@"%.02f"];
        [self f03modreccametifacconf:RR2 Campo:@"Rendimiento" etiqueta:RR2.LRendimiento factor:neg config:@"%.02f"];
        [self f03modreccametifacconf:RR3 Campo:@"Rendimiento" etiqueta:RR3.LRendimiento factor:neg config:@"%.02f"];
        [self f03modreccametifacconf:RR4 Campo:@"Rendimiento" etiqueta:RR4.LRendimiento factor:neg config:@"%.02f"];
        [self f03modreccametifacconf:RR5 Campo:@"Rendimiento" etiqueta:RR5.LRendimiento factor:neg config:@"%.02f"];
        [self f03modreccametifacconf:RR6 Campo:@"Rendimiento" etiqueta:RR6.LRendimiento factor:neg config:@"%.02f"];

        [self f05modindicadorcamfacgracon:@"GQuality" factor:neg2 gra:calidad config:@"%f"];
        [self f05modindicadorcamfacgracon:@"GRisk" factor:neg2 gra:riesgo config:@"%f"];
        
        [self f06modcamfacconf:@"Training" factor:pos1 config:@"%f"];
        [self f06modcamfacconf:@"Procurement" factor:pos1 config:@"%f"];
       
        
        
        NSLog(@"Quality");
    }
    
}
-(void)eventoriesgo{
    
}
-(void)eventocalidad{
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)setselected:(NSString*)seleccion fun:(NSString*)fun{
    
}

-(void)setselectedA:(NSString*)seleccion fun:(NSString*)fun{
    
}

@end
