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
#import "EJSEasyJsonParameterObject.h"

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
        easyJsonConfig = [[NSMutableArray alloc]initWithArray:[self readConfigFile]];
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
    // Find the config object for the specified class
    EJSEasyJsonObject *configObject = [self getConfigForClass:NSStringFromClass(objectClass)];
    
    // JSON values
    NSDictionary *jsonValues = [jsonDictionary objectForKey:configObject.classInfo.jsonKey];
    
    // 1 Nsmanagedobject
    NSManagedObject *managedObject = [NSEntityDescription insertNewObjectForEntityForName:configObject.classInfo.attribute inManagedObjectContext:[EJSDatabaseManager sharedInstance].databaseCore.managedObjectContext];
    
    // Parameters
    for (EJSEasyJsonParameterObject *parameter in configObject.parameters)
    {
        // Property description (Attribute or reliationship)
        NSPropertyDescription *propertyDescription = [self getPropertyDescriptionForValueObject:parameter withJsonDict:jsonValues withManagedObject:managedObject];
        
        // Formated value after json parsing
        id managedObjectValue = [self getParameterForValueObject:parameter withJsonDict:jsonValues withPropertyDescription:propertyDescription];
        
        // Attribute
        if ((managedObjectValue) && (![managedObjectValue isKindOfClass:[NSSet class]]))
        {
           [managedObject setValue:managedObjectValue forKey:parameter.attribute];
        }
        // Relationship
        else if ((managedObjectValue) && ([managedObjectValue isKindOfClass:[NSSet class]]))
        {
            [managedObject setValue:managedObjectValue forKey:parameter.attribute];
        }
    }
    return managedObject;
}


#pragma mark - Helper

// Get property description
- (NSPropertyDescription *)getPropertyDescriptionForValueObject:(EJSEasyJsonParameterObject *)valueObject
                                                   withJsonDict:(NSDictionary *)jsonDict withManagedObject:(NSManagedObject *)managedObject
{
    NSEntityDescription *entityDescription = [managedObject entity];
    NSPropertyDescription *propertyDescription;
    
    if ([self checkIfKey:valueObject.jsonKey ExistIn:jsonDict]) {
        // Search concerned property
        for (NSString *propertyKey in [[entityDescription propertiesByName] allKeys]) {
            if ([propertyKey isEqual:valueObject.attribute]) {
                propertyDescription = [[entityDescription propertiesByName] objectForKey:propertyKey];
                break;
            }
        }
    }
    return propertyDescription;
}


// Get formated parameter
- (id)getParameterForValueObject:(EJSEasyJsonParameterObject *)valueObject withJsonDict:(NSDictionary *)jsonDict withPropertyDescription:(NSPropertyDescription *)propertyDescription
{

    // Get the formated value or set
    if ([propertyDescription isKindOfClass:[NSAttributeDescription class]]) {
        NSString *jsonString = [jsonDict objectForKey:valueObject.jsonKey];
        return [self returnFormatedAttributeValue:(NSAttributeDescription *)propertyDescription withJson:jsonString];
    } else if ([propertyDescription isKindOfClass:[NSRelationshipDescription class]]) {
        NSArray *jsonArray = [jsonDict objectForKey:valueObject.jsonKey];
        return [self returnSetForRelationship:(NSRelationshipDescription *)propertyDescription withJson:jsonArray];
    }
    
    return nil;
}


- (id)returnFormatedAttributeValue:(NSAttributeDescription *)attributeDescription withJson:(NSString *)jsonString
{
    // Return correct value depending of the type
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
    return nil;
}

- (NSSet *)returnSetForRelationship:(NSRelationshipDescription *)relationship withJson:(NSArray *)jsonArray
{
    NSMutableSet *set = [NSMutableSet set];
    for (NSDictionary *jsonDict in jsonArray) {
        [set addObject:[self analyzeDictionary:jsonDict forClass:NSClassFromString([[relationship destinationEntity] managedObjectClassName])]];
    }
    return [NSSet setWithSet:set];
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
        if ([className isEqual:ejsJsonObject.classInfo.attribute]) {
            return ejsJsonObject;
        }
    }
    return nil;
}

- (NSArray *)readConfigFile
{
    NSString *configFilepath = [[NSBundle mainBundle] pathForResource:@"EasyJsonConfig" ofType:@"json"];
    
    if (configFilepath) {
        NSData *configContent = [NSData dataWithContentsOfFile:configFilepath];
        return [self getConfigFromData:configContent];
    }
    return @[];
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
        ejsClassObject.jsonKey = [[configOcurrence objectForKey:@"class"] objectForKey:@"json"];
        ejsClassObject.type = [[configOcurrence objectForKey:@"class"] objectForKey:@"type"];
        ejsObject.classInfo = ejsClassObject;
        
        
        for (NSDictionary *value in [configOcurrence objectForKey:@"parameters"]) {
            EJSEasyJsonParameterObject *ejsValueObject =  [[EJSEasyJsonParameterObject alloc]init];
            ejsValueObject.attribute = [value objectForKey:@"attribute"];
            ejsValueObject.jsonKey = [value objectForKey:@"json"];
            [ejsObject.parameters addObject:ejsValueObject];
        }
        [resultArray addObject:ejsObject];
    }
    return resultArray;
}
/* Set inverse
 
 
 //            NSString *inverseRelationshipKey = [((NSRelationshipDescription *)propertyDescription).inverseRelationship name];
 //            for (NSManagedObject *relationManagedObject in [managedObjectValue allObjects]) {
 //                NSMutableSet *inverseRelationshipSet = [relationManagedObject mutableSetValueForKey:inverseRelationshipKey];
 //                [inverseRelationshipSet addObject:managedObject];
 //            }
 */
 


@end
