//
//  Help.m
//  CMSimulator
//
//  Created by Enrique Galicia on 09/11/15.
//  Copyright © 2015 Enrique Galicia. All rights reserved.
//

#import "Help.h"

@interface Help ()

@end


@implementation Help
@synthesize delehelpo;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    NSLog (@"ejecute");
    [self.delehelpo exithelp];

    
    
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
