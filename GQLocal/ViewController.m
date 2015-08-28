//
//  ViewController.m
//  GQLocal
//
//  Created by James Tomson on 8/27/15.
//  Copyright (c) 2015 James Tomson. All rights reserved.
//

#import "GQLocal.h"
#import "StarWarsData.h"

#import "ViewController.h"

#import <FBKVOController.h>

@interface ViewController ()
@property (nonatomic) GQLocal *gqlocal;
@property (nonatomic) FBKVOController *kvo;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.gqlocal = [[GQLocal alloc] init];
    
    [self.gqlocal bindJSResolver:@"getHero" resolver:^(NSDictionary *root, NSArray *args, void (^callback)(id)) {
        callback([StarWarsData hero:args[0]]);
    }];
    
    [self.gqlocal bindJSResolver:@"getFriends" resolver:^(NSDictionary *root, NSArray *args, void (^callback)(id)) {
        callback([StarWarsData friends:args[0]]);
    }];
    
    [self.gqlocal bindJSResolver:@"getHuman" resolver:^(NSDictionary *root, NSArray *args, void (^callback)(id)) {
        callback([StarWarsData human:args[0]]);
    }];
    
    [self.gqlocal bindJSResolver:@"getDroid" resolver:^(NSDictionary *root, NSArray *args, void (^callback)(id)) {
        callback([StarWarsData droid:args[0]]);
    }];
    
    NSURL *schemaURL = [[NSBundle mainBundle] URLForResource:@"bridgedStarWarsSchema" withExtension:@"js"];
    [self.gqlocal loadSchemaFileURL:schemaURL jsName:@"StarWarsSchema"];
    
    self.kvo = [FBKVOController controllerWithObserver:self];
    
    [self.kvo observe:self.gqlocal keyPath:@"isReady" options:NSKeyValueObservingOptionNew block:^(id observer, id object, NSDictionary *change) {
        
    }];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.gqlocal query:@"{ hero { name friends { name appearsIn friends { name } } } }" schema:@"StarWarsSchema" response:^(NSDictionary *result, NSError *error) {
            NSLog(@"******** %@, %@", result, error);
        }];
    });
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
