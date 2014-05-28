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
#import <objc/runtime.h>

#define EASY_JSON_ENVELOPE_WITH_OBJECT_NAME 0
#define EASY_JSON_DATE_FORMAT @"yyyy-MM-dd"

#define NSNumWithInt(i)                         ([NSNumber numberWithInt:(i)])
#define NSNumWithFloat(f)                       ([NSNumber numberWithFloat:(f)])
#define NSNumWithBool(b)                        ([NSNumber numberWithBool:(b)])
#define NSNumWithDouble(d)                      ([NSNumber numberWithDouble:(d)])
#define NSNumWithLong(l)                        ([NSNumber numberWithLong:(l)])
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
        [dateFormater setDateFormat:EASY_JSON_DATE_FORMAT];
    }
    return self;
}

-(void)dealloc
{
}


#pragma mark - Analyze

- (NSArray *)analyzeArray:(NSArray *)jsonArray forClass:(Class)objectClass
{
    NSMutableArray *resultArray = [[NSMutableArray alloc]init];
    for (int i = 0; i < jsonArray.count; i++) {
        if ([[jsonArray objectAtIndex:i] isKindOfClass:[NSDictionary class]]) {
            [resultArray addObject:[self analyzeDictionary:[jsonArray objectAtIndex:i] forClass:objectClass]];
        }
    }
    return resultArray;
}

- (id)analyzeDictionary:(NSDictionary *)jsonDictionary forClass:(Class)objectClass
{
    // Find the config object for the specified class
    EJSEasyJsonObject *configObject = [self getConfigForClass:NSStringFromClass(objectClass)];
    
    // JSON values
    NSDictionary *jsonValues = jsonDictionary;
    if (EASY_JSON_ENVELOPE_WITH_OBJECT_NAME)
        jsonValues = [jsonDictionary objectForKey:configObject.classInfo.jsonKey];
    
    if ( class_getSuperclass(objectClass) == [NSManagedObject class]) {
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
    else {
        id object = [[objectClass alloc]init];

        // Parameters
        for (EJSEasyJsonParameterObject *parameter in configObject.parameters)
        {
            // Formated value after json parsing
//            id objectValue = [self getObjectParameterForValueObject:parameter withJsonDict:jsonDictionary withObjcProperty:property];
            [self setObjectParameterForValueObject:parameter withJsonDict:jsonDictionary withObject:object];
//            [object setValue:objectValue forKeyPath:[NSString stringWithUTF8String:property_getName(property)]];
        }
        return object;
    }
    return nil;
}

#pragma mark - Helper Managed Object

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


#pragma mark - Helper NSObject

// Get the type of property from NSObject according to the EasyJsonParameterObject
- (objc_property_t) getObjectPropertyForValueObject:(EJSEasyJsonParameterObject *)valueObject withObject:(NSObject *)object
{
    objc_property_t propertyResult = NULL;
    unsigned propertyCount;
    
    // Each properties
    objc_property_t *objectProperties = class_copyPropertyList([object class], &propertyCount);
    for (int i = 0; i < propertyCount; i++) {
        // If Property corresponding with EasyJsonParameterObject
        if ([[NSString stringWithUTF8String:property_getName(objectProperties[i])] isEqual:valueObject.attribute]) {
            propertyResult = objectProperties[i];
            break;
        }
    }
    return propertyResult;
}

// Get the value formated of specific property from JSON
- (id)setObjectParameterForValueObject:(EJSEasyJsonParameterObject *)valueObject withJsonDict:(NSDictionary *)jsonDict withObject:(id)object
{
    // Json
    NSString *jsonString = [jsonDict objectForKey:valueObject.jsonKey];

    // Property
    objc_property_t property = [self getObjectPropertyForValueObject:valueObject withObject:object];
    const char *propertyType = property_getAttributes(property);
    NSString *propertyKey = [NSString stringWithUTF8String:property_getName(property)];
    
    fprintf(stdout, "%s \n", propertyType);

    // Float
    if (propertyType[1] == 'f') {
        [object setValue:NSNumWithFloat([jsonString floatValue]) forKey:propertyKey];
    }
    // Short // TODO
    else if (propertyType[1] == 's') {
        NSLog(@"SHORT");
    }
    // Int or nsinteger // TODO
    else if (propertyType[1] == 'i') {
        [object setValue:NSNumWithInt([jsonString intValue]) forKey:propertyKey];
    }
    // Double
    else if (propertyType[1] == 'd') {
        [object setValue:NSNumWithFloat([jsonString floatValue]) forKey:propertyKey];
    }
    // Long
    else if(propertyType[1] == 'd' ) {
        [object setValue:NSNumWithDouble([jsonString doubleValue]) forKey:propertyKey];
    }
    // Bool
    else if(propertyType[1] == 'c' ) {
        [object setValue:NSNumWithBool([jsonString boolValue]) forKey:propertyKey];
    }
    // NSObject
    else if (propertyType[1] == '@') {
        // Get NSType from propertyType
        NSString * typeString = [NSString stringWithUTF8String:propertyType];
        NSArray * attributes = [typeString componentsSeparatedByString:@","];
        NSString * typeAttribute = [attributes objectAtIndex:0];
        NSString * typeClassName = [typeAttribute substringWithRange:NSMakeRange(3, [typeAttribute length]-4)];
        
        // Get Class
        Class typeClass = NSClassFromString(typeClassName);
        
        if (typeClass != nil) {
            // NSDate
            if (typeClass == [NSDate class]) {
                [object setValue:[dateFormater dateFromString:jsonString] forKey:propertyKey];
            }
            // NSString
            else if (typeClass == [NSString class]) {
                [object setValue:jsonString forKey:propertyKey];
            }
            // NSNumber
            else if(typeClass == [NSNumber class]) {
                NSNumberFormatter *numFormatter = [[NSNumberFormatter alloc] init];
                [numFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
                [object setValue:[numFormatter numberFromString:jsonString] forKey:propertyKey];
            }
            // NSData
            else if(typeClass == [NSData class]) {
                [object setValue:[jsonString dataUsingEncoding:NSUTF8StringEncoding] forKey:propertyKey];
            }
        }
    }
    return nil;
}


#pragma mark - Helper

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
 


@end
