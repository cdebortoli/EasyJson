//
//  EasyJsonTests.m
//  EasyJsonTests
//
//  Created by cdebortoli on 23/05/14.
//  Copyright (c) 2014 EJS. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "EJSEasyJson.h"

@interface EasyJsonTests : XCTestCase

@end

@implementation EasyJsonTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testEasyJson
{
    NSArray *mockFiles = [self getMockJson];
    for (NSString *mockPath in mockFiles) {
        NSData *fileContent = [NSData dataWithContentsOfFile:mockPath];
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:fileContent options:kNilOptions error:nil];
        id mock = [json objectForKey:@"mock"];
        if ([mock isKindOfClass:[NSDictionary class]]) {
            
            NSManagedObject *managedObject = [[EJSEasyJson sharedInstance] analyzeDictionary:mock forClass:NSClassFromString([json objectForKey:@"class"])];
            [self analyzeManagedObject:managedObject];
        }
        else if ([mock isKindOfClass:[NSArray class]]) {
            NSArray *managedObjects = [[EJSEasyJson sharedInstance] analyzeArray:mock forClass:NSClassFromString([json objectForKey:@"class"])];
            for (NSManagedObject *managedObject in managedObjects) {
                [self analyzeManagedObject:managedObject];
            }
        }
    }
}


- (void)analyzeManagedObject:(NSManagedObject *)managedObject
{
    for (NSString *attributeKey in [[[managedObject entity] attributesByName] allKeys]) {
        id result = [managedObject valueForKey:attributeKey];
        XCTAssertNotNil(result, @"Check attributeKey : %@", attributeKey);
    }
    
    for (NSString *relationKey in [[[managedObject entity] relationshipsByName] allKeys]) {
        NSSet *results = [managedObject valueForKey:relationKey];
        XCTAssert(results.count > 0, @"Check relation : %@", relationKey);
    }
}

- (NSMutableArray *)getMockJson
{
    
    NSMutableArray *filePaths = [[NSMutableArray alloc] init];
    
    // Enumerators are recursive
    NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtPath:[[NSBundle mainBundle] bundlePath]];
    
    NSString *filePath;
    
    while ((filePath = [enumerator nextObject]) != nil){
        if (([[filePath pathExtension] isEqualToString:@"json"]) && ([filePath length] > 12) && ([[filePath substringToIndex:12] isEqual:@"EasyJsonMock"])){
            [filePaths addObject:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:filePath]];
        }
    }
    
    
    return filePaths;
}

@end
