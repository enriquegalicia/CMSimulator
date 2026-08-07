//
//  Scores.m
//  CMSimulator
//
//  Created by Enrique Galicia on 05/11/15.
//  Copyright © 2015 Enrique Galicia. All rights reserved.
//

#import "Scores.h"

@interface Scores ()

@end

@implementation Scores
@synthesize delescore=_delescore,valores,TaScores;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    TaScores=[[TiElTaA alloc]init];
    TaScores.view.frame=IvTaScores.frame;
    TaScores.delegadores5=self;
    [self.view addSubview:TaScores.view];
    valores=[[NSMutableDictionary alloc]init];
    
    // Do any additional setup after loading the view from its nib.
}
-(void)cargartablageneral:(NSMutableDictionary*)tabla{
    
    [valores setObject:[tabla objectForKey:@"Costos"] forKey:@"Costos"];
    [valores setObject:[tabla objectForKey:@"Tiempos"] forKey:@"Tiempos"];
    [valores setObject:[tabla objectForKey:@"Total"] forKey:@"Total"];
    NSLog(@"%@tabla",[tabla objectForKey:@"Total"]);
    [TaScores cargartablas:[tabla objectForKey:@"Total"]];
    
}
-(void)viewWillAppear:(BOOL)animated{
    NSLog(@"Aparesco");
    [TaScores ocurrir];
    [super viewWillAppear:YES];
}
-(NSDictionary*)obtenerinformacion{
    NSMutableDictionary *diccionario=[self.delescore obtenerinformacion2];
    [valores setObject:[diccionario objectForKey:@"Costos"] forKey:@"Costos"];
    [valores setObject:[diccionario objectForKey:@"Tiempos"] forKey:@"Tiempos"];
    [valores setObject:[diccionario objectForKey:@"Total"] forKey:@"Total"];
    NSDictionary *uso=[diccionario objectForKey:@"Total"];
    return uso;
}


-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    UITouch *touch =[touches anyObject];
    if ([touch view]==IvCost) {
        [TaScores cargartablas:[valores objectForKey:@"Costos"]];
        IvTitulo.text=@"Cost Master Leaderboard";
    }
    if ([touch view]==IvTime) {
        [TaScores cargartablas:[valores objectForKey:@"Tiempos"]];
        IvTitulo.text=@"Time Master Leaderboard";
    }
    if ([touch view]==IvMaster) {
        [TaScores cargartablas:[valores objectForKey:@"Total"]];
        IvTitulo.text=@"Construction Master Leaderboard";
    }
    if ([touch view]==Exit) {
        [self.delescore exit];
    }
}


-(void)setselected:(NSString*)seleccion fun:(NSString*)fun{
    
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
