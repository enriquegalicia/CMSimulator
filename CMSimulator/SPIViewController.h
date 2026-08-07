//
//  SPIViewController.h
//  Clases
//
//  Created by Enrique Galicia on 15/08/13.
//  Copyright (c) 2013 MAG Architecture and Technology Solutions. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SPI.h"

@interface SPIViewController : UIViewController{
    IBOutlet UILabel *Lpspi;
    IBOutlet SPI *spi;
    double pspi;
    
    IBOutlet UITextField *texto;

}
-(IBAction)cambiar:(id)sender;

@end
