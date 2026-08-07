//
//  Result.m
//  CMSimulator
//
//  Created by Enrique Galicia on 05/11/15.
//  Copyright © 2015 Enrique Galicia. All rights reserved.
//

#import "Result.h"

@interface Result ()

@end

@implementation Result
@synthesize LCost,LTime,TfNombre,Save,deleresult=_deleresult,fcosto,ftiempo;

- (void)viewDidLoad {
    [super viewDidLoad];
    /*float costo=[self randomFloatBetween:1000000 and:4000000];
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setNumberStyle: NSNumberFormatterCurrencyStyle];
    NSString *numberAsString = [numberFormatter stringFromNumber:[NSNumber numberWithFloat:costo]];
    LCost.text=numberAsString;
    fcosto=costo;
    float dias=[self randomFloatBetween:50 and:180];
    ftiempo=dias;
    int diastot=dias;
    float horas=(dias-diastot)*8;
    int horast=horas;
    NSString *tiempo=[NSString stringWithFormat:@"%i Days %i Hours",diastot,horast];
    LTime.text=tiempo;*/
    
    // Do any additional setup after loading the view from its nib.
}

- (float)randomFloatBetween:(float)smallNumber and:(float)bigNumber {
    float diff = bigNumber - smallNumber;
    return (((float) (arc4random() % ((unsigned)RAND_MAX + 1)) / RAND_MAX) * diff) + smallNumber;
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    UITouch *touch =[touches anyObject];
    if ([touch view]==Save) {
        NSMutableDictionary* info=[[NSMutableDictionary alloc]init];
        [info setObject:[NSString stringWithFormat:@"%.02f",fcosto] forKey:@"Costo"];
        [info setObject:[NSString stringWithFormat:@"%.02f",ftiempo] forKey:@"Tiempo"];
        [info setObject:TfNombre.text forKey:@"Nombre"];        
        [self.deleresult resultado:info];
        
    }
}
-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:YES];

     NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
     [numberFormatter setNumberStyle: NSNumberFormatterCurrencyStyle];
     NSString *numberAsString = [numberFormatter stringFromNumber:[NSNumber numberWithFloat:fcosto]];
     LCost.text=numberAsString;
     int diastot=ftiempo;
     float horas=(ftiempo-diastot)*8;
     int horast=horas;
     NSString *tiempo=[NSString stringWithFormat:@"%i Days %i Hours",diastot,horast];
     LTime.text=tiempo;
    
    
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
