//
//  EasyJsonTests.m
//  EasyJsonTests
//
//  Created by cdebortoli on 23/05/14.
//  Copyright (c) 2014 EJS. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "EJSEasyJson.h"
#import <objc/runtime.h>

#import "EJSEasyJsonObject.h"
#import "EJSEasyJsonParameterObject.h"

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
            Class mockClass = NSClassFromString([json objectForKey:@"class"]);
            // Manage object
            if (class_getSuperclass(mockClass) == [NSManagedObject class])
            {
                NSManagedObject *managedObject = [[EJSEasyJson sharedInstance] analyzeDictionary:mock forClass:mockClass];
                [self analyzeManagedObject:managedObject];
            }
            // NSobject
            else
            {
                NSObject *customObject = [[EJSEasyJson sharedInstance] analyzeDictionary:mock forClass:mockClass];
                [self analyseObject:customObject];
            }
        }
        else if ([mock isKindOfClass:[NSArray class]]) {
            Class mockClass = NSClassFromString([json objectForKey:@"class"]);
            // Managed object
            if (class_getSuperclass(mockClass) == [NSManagedObject class])
            {
                NSArray *managedObjects = [[EJSEasyJson sharedInstance] analyzeArray:mock forClass:mockClass];
                for (NSManagedObject *managedObject in managedObjects) {
                    [self analyzeManagedObject:managedObject];
                }
            } else
            // NSobject
            {
                NSArray *customObjects = [[EJSEasyJson sharedInstance] analyzeArray:mock forClass:mockClass];
                for (id object in customObjects) {
                    [self analyseObject:object];
                }
            }
        }
    }
}


- (void)analyzeManagedObject:(NSManagedObject *)managedObject
{
    EJSEasyJsonObject *configObject = [[EJSEasyJson sharedInstance] getConfigForClass:NSStringFromClass([managedObject class])];
    for (EJSEasyJsonParameterObject *parameter in configObject.parameters) {
        NSPropertyDescription *propertyDescription = [[EJSEasyJson sharedInstance] getPropertyDescriptionFromManagedObject:managedObject withParameter:parameter];
        if ((propertyDescription) && ([propertyDescription isKindOfClass:[NSAttributeDescription class]])) {
            id result = [managedObject valueForKey:parameter.attribute];
            XCTAssertNotNil(result, @"Check attributeKey : %@", parameter.attribute);
        } else if ((propertyDescription) && ([propertyDescription isKindOfClass:[NSRelationshipDescription class]])) {
            NSSet *results = [managedObject valueForKey:parameter.attribute];
            XCTAssert(results.count > 0, @"Check relation : %@", parameter.attribute);
        }
    }
}

- (void)analyseObject:(id)object
{
    EJSEasyJsonObject *configObject = [[EJSEasyJson sharedInstance] getConfigForClass:NSStringFromClass([object class])];
    for (EJSEasyJsonParameterObject *parameter in configObject.parameters) {
        objc_property_t property = [[EJSEasyJson sharedInstance] getPropertyFromObject:object withParameter:parameter];
        if (property) {
            const char *propertyType = property_getAttributes(property);
            
            id value = [object valueForKey:parameter.attribute];
            
            if ([value isKindOfClass:[NSArray class]]) {
                XCTAssert(((NSArray *)value).count > 0, @"Check Array : %@", parameter.attribute);
            } else if ([value isKindOfClass:[NSDictionary class]]) {
                XCTAssert(((NSDictionary *)value).count > 0, @"Check Dictionary : %@", parameter.attribute);
            } else if((value != nil) && (propertyType[1] == '@')) { // String
                XCTAssertNotNil(value, @"Check String : %@", parameter.attribute);
            } else if ([value isKindOfClass:[NSNumber class]]) { // Number or primitive
                XCTAssertNotNil(value, @"Check Number : %@", parameter.attribute);
            }
        }
    }
}

- (NSMutableArray *)getMockJson
{
    
    NSMutableArray *filePaths = [[NSMutableArray alloc] init];
    
    // Enumerators are recursive
    NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtPath:[[NSBundle bundleForClass:[self class] ] bundlePath]];
    
    NSString *filePath;
    
    while ((filePath = [enumerator nextObject]) != nil){
        if (([[filePath pathExtension] isEqualToString:@"json"]) && ([filePath length] > 12) && ([[filePath substringToIndex:12] isEqual:@"EasyJsonMock"])){
            [filePaths addObject:[[[NSBundle bundleForClass:[self class] ] bundlePath] stringByAppendingPathComponent:filePath]];
        }
    }
    
    
    return filePaths;
}

@end
