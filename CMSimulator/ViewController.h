//
//  ViewController.h
//  CMSimulator
//
//  Created by Enrique Galicia on 26/10/15.
//  Copyright © 2015 Enrique Galicia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SPI.h"
#import "Recurso.h"
#import "Potenciadores.h"
#import <GameKit/Gamekit.h>
#import "GestorBD.h"
#import "Scores.h"
#import "Result.h"
#import "Intro.h"
#import "Help.h"

@interface ViewController : UIViewController<recursoA,potA,result,scorespro,helpopro,introA,GKGameCenterControllerDelegate>{
    
    IBOutlet SPI *riesgo;
    IBOutlet SPI *calidad;
    IBOutlet UIImageView *IvR1;
    IBOutlet UIImageView *IvR2;
    IBOutlet UIImageView *IvR3;
    IBOutlet UIImageView *IvR4;
    IBOutlet UIImageView *IvR5;
    IBOutlet UIImageView *IvR6;
    Recurso *RR1;
    Recurso *RR2;
    Recurso *RR3;
    Recurso *RR4;
    Recurso *RR5;
    Recurso *RR6;
    IBOutlet UIImageView *IvP1;
    IBOutlet UIImageView *IvP2;
    IBOutlet UIImageView *IvP3;
    IBOutlet UIImageView *IvP4;
    IBOutlet UIImageView *IvP5;
    IBOutlet UIImageView *IvP6;
    Potenciadores *RP1;
    Potenciadores *RP2;
    Potenciadores *RP3;
    Potenciadores *RP4;
    Potenciadores *RP5;
    Potenciadores *RP6;
    IBOutlet UIImageView *pause;
    IBOutlet UIImageView *play;
    IBOutlet UIImageView *fastforward;
    IBOutlet UILabel *totalcost;
    IBOutlet UILabel *totaltime;
    IBOutlet UILabel *totalprogress;
    NSTimer *Temporal;
    NSTimer *Eventos;
    int dias;
    float fdias;
    GestorBD* gestorbd;
    Scores *ScoresA;
    Result *ResultA;
    Intro *Intro1;
    Help *helpo;
    IBOutlet UIImageView *help;
    IBOutlet UIImageView *gamecenter;
    IBOutlet UIImageView *scores;

    NSMutableDictionary *valores;
    
    
}

-(void)RPLUS;
-(void)RMINUS;
-(void)authenticateLocalPlayer;
-(void)reportScore;
-(void)showLeaderboardAndAchievements:(BOOL)shouldShowLeaderboard;
-(void)exithelp;

@end

