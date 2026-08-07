//
//  SPIViewController.m
//  Clases
//
//  Created by Enrique Galicia on 15/08/13.
//  Copyright (c) 2013 MAG Architecture and Technology Solutions. All rights reserved.
//

#import "SPIViewController.h"

@interface SPIViewController ()

@end

@implementation SPIViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    pspi = 3;
    spi.pspi=pspi;
    
    [Lpspi setText:[NSString stringWithFormat:@"%.1f", pspi]];
    [Lpspi setTextColor:[UIColor blackColor]];
    [Lpspi setFont:[UIFont fontWithName: @"Futura-CondensedMedium" size: 8]];
    
    // Do any additional setup after loading the view from its nib.
}
-(IBAction)cambiar:(id)sender{
    if ([texto.text isEqualToString:@""]) {
        
    }
    else{
        
    }
    [spi setPspi:[texto.text intValue]];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
