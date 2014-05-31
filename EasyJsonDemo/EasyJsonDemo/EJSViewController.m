//
//  EJSViewController.m
//  EasyJsonDemo
//
//  Created by christophe on 29/05/14.
//  Copyright (c) 2014 cdebortoli. All rights reserved.
//

#import "EJSViewController.h"
#import "EJSEasyJson.h"
#import "EJSCustomObject.h"

@interface EJSViewController ()

@end

@implementation EJSViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    
    Aircraft *a1 = [[EJSEasyJson sharedInstance] analyzeDictionary:[self loadService:@"aircraftJson"] forClass:[Aircraft class]];
//    NSLog(@"%@",a1);
    
    
//    Aircraft *a2 = [[EJSEasyJson sharedInstance] analyzeDictionary:[self loadService:@"aircraftJsonWithEnvelope"] forClass:[Aircraft class]];
//    NSLog(@"%@",a2);
    
    EJSCustomObject *customObject = [[EJSEasyJson sharedInstance] analyzeDictionary:[self loadService:@"customObjectJson"] forClass:[EJSCustomObject class]];
//    NSLog(@"%@", customObject);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSDictionary *)loadService:(NSString *)jsonFileName
{
    NSString *fp = [[NSBundle mainBundle] pathForResource:jsonFileName ofType:@"json"];
    NSData *fileContent = [NSData dataWithContentsOfFile:fp];
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:fileContent options:kNilOptions error:nil];
    return json;
}

@end
