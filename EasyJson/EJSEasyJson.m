//
//  EJSEasyJson.m
//  EasyJson
//
//  Created by cdebortoli on 23/05/14.
//  Copyright (c) 2014 EJS. All rights reserved.
//

#import "EJSEasyJson.h"
#import "EJSEasyJsonClassObject.h"
#import "EJSEasyJsonObject.h"
#import "EJSEasyJsonValueObject.h"

#define DATE_FORMAT @"yyyy-MM-dd"

#define NSNumWithInt(i)                         ([NSNumber numberWithInt:(i)])
#define NSNumWithFloat(f)                       ([NSNumber numberWithFloat:(f)])
#define NSNumWithBool(b)                        ([NSNumber numberWithBool:(b)])
#define NSNumWithDouble(d)                      ([NSNumber numberWithDouble:(d)])
#define IntFromNSNum(n)                         ([(n) intValue])
#define FloatFromNSNum(n)                       ([(n) floatValue])
#define BoolFromNSNum(n)                        ([(n) boolValue])
#define ToString(o)                             [NSString stringWithFormat:@"%@", (o)]

@implementation EJSEasyJson
{
    NSMutableArray *easyJsonConfig;
    NSDateFormatter *dateFormater;
}

static EJSEasyJson __strong *sharedInstance = nil;


#pragma mark - Init

+(EJSEasyJson *)sharedInstance
{
    static dispatch_once_t pred;
    dispatch_once(&pred, ^{
        sharedInstance = [[EJSEasyJson alloc]init];
    });
    return sharedInstance;
}

-(id)init
{
    self = [super init];
    if (self != nil)
    {
        easyJsonConfig = [[NSMutableArray alloc]init];
        NSString *configFilepath = [[NSBundle mainBundle] pathForResource:@"EasyJsonConfig" ofType:@"json"];
        
        if (configFilepath) {
            NSData *configContent = [NSData dataWithContentsOfFile:configFilepath];
            [easyJsonConfig setArray: [self getConfigFromData:configContent]];
        }
        
        if (configFilepath == nil){
            // Log error
        }

        dateFormater = [[NSDateFormatter alloc] init];
        [dateFormater setDateFormat:DATE_FORMAT];
    }
    return self;
}

-(void)dealloc
{
}


#pragma mark - Analyze

- (NSArray *)analyzeArray:(NSArray *)jsonArray forClass:(id)objectClass
{
    NSMutableArray *resultArray = [[NSMutableArray alloc]init];
    for (int i = 0; i < jsonArray.count; i++) {
        if ([[jsonArray objectAtIndex:i] isKindOfClass:[NSDictionary class]]) {
            [resultArray addObject:[self analyzeDictionary:[jsonArray objectAtIndex:i] forClass:objectClass]];
        }
    }
    
    return nil;
}

- (id)analyzeDictionary:(NSDictionary *)jsonDictionary forClass:(id)objectClass
{
    // Config Object
    EJSEasyJsonObject *configObject = [self getConfigForClass:NSStringFromClass(objectClass)];
    
    // JSON
    NSDictionary *jsonValues = [jsonDictionary objectForKey:configObject.classDetail.json];
    
    // 1 Nsmanagedobject
    NSManagedObject *managedObject = [NSEntityDescription insertNewObjectForEntityForName:configObject.classDetail.attribute inManagedObjectContext:[EJSDatabaseManager sharedInstance].databaseCore.managedObjectContext];
    
    for (EJSEasyJsonValueObject *value in configObject.values) {
        
        id managedObjectValue = [self setParameterForValueObject:value withJsonDict:jsonValues withManagedObject:managedObject];
        if (managedObjectValue)
           [managedObject setValue:managedObjectValue forKey:value.attribute];
    }
    return managedObject;
}



- (id)setParameterForValueObject:(EJSEasyJsonValueObject *)valueObject withJsonDict:(NSDictionary *)jsonDict withManagedObject:(NSManagedObject *)managedObject
{
    if ([self checkIfKey:valueObject.json ExistIn:jsonDict]) {
        NSString *jsonString = [jsonDict objectForKey:valueObject.json];
        
        NSEntityDescription *entityDescription = [managedObject entity];
        
        // Search attribute
        NSAttributeDescription *attributeDescription;
        for (NSString *attributeKey in [[entityDescription attributesByName] allKeys]) {
           if ([attributeKey isEqual:valueObject.attribute])
           {
               attributeDescription = [[entityDescription attributesByName] objectForKey:attributeKey];
           }
        }
        switch (attributeDescription.attributeType) {
            case NSInteger16AttributeType:
            case NSInteger32AttributeType:
            case NSInteger64AttributeType:
            {
                return NSNumWithInt([jsonString intValue]);
                break;
            }
            case NSDecimalAttributeType:
            {
                return NSNumWithFloat([jsonString floatValue]);
                break;
            }
            case NSDoubleAttributeType:
            {
                return NSNumWithDouble([jsonString doubleValue]);
                break;
            }
            case NSFloatAttributeType:
            {
                return NSNumWithFloat([jsonString floatValue]);
                break;
            }
            case NSStringAttributeType:
            {
                return jsonString;
                break;
            }
            case NSBooleanAttributeType:
            {
                return NSNumWithBool([jsonString boolValue]);
                break;
            }
            case NSDateAttributeType:
            {
                return [dateFormater dateFromString:jsonString];
                break;
            }
            case NSBinaryDataAttributeType:
            {
                
                break;
            }
            case NSTransformableAttributeType:
            {
                
                break;
            }
            case NSObjectIDAttributeType:
            {
                
                break;
            }
            default:
                break;
        }
    }
    return nil;
}

- (BOOL)checkIfKey:(NSString *)key ExistIn:(NSDictionary *)dict
{
    if([dict objectForKey:key] != nil && [dict objectForKey:key] != [NSNull null])
        return YES;
    else
        return NO;
}


#pragma mark - Config

// Get the config object from a particular class
- (EJSEasyJsonObject *)getConfigForClass:(NSString *)className
{
    for (EJSEasyJsonObject *ejsJsonObject in easyJsonConfig) {
        if ([className isEqual:ejsJsonObject.classDetail.attribute]) {
            return ejsJsonObject;
        }
    }
    return nil;
}

// Parse config from config file
- (NSArray *)getConfigFromData:(NSData *)data
{
    NSMutableArray *resultArray = [[NSMutableArray alloc]init];
    NSError *jsonError;
    for (NSDictionary *configOcurrence in [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&jsonError]) {
        EJSEasyJsonObject *ejsObject = [[EJSEasyJsonObject alloc]init];
        
        EJSEasyJsonClassObject *ejsClassObject = [[EJSEasyJsonClassObject alloc]init];
        ejsClassObject.attribute = [[configOcurrence objectForKey:@"class"] objectForKey:@"attribute"];
        ejsClassObject.json = [[configOcurrence objectForKey:@"class"] objectForKey:@"json"];
        ejsClassObject.type = [[configOcurrence objectForKey:@"class"] objectForKey:@"type"];
        ejsObject.classDetail = ejsClassObject;
        
        
        for (NSDictionary *value in [configOcurrence objectForKey:@"parameters"]) {
            EJSEasyJsonValueObject *ejsValueObject =  [[EJSEasyJsonValueObject alloc]init];
            ejsValueObject.attribute = [value objectForKey:@"attribute"];
            ejsValueObject.json = [value objectForKey:@"json"];
            ejsValueObject.type = [value objectForKey:@"type"];
            [ejsObject.values addObject:ejsValueObject];
        }
        [resultArray addObject:ejsObject];
    }
    return resultArray;
}



@end
