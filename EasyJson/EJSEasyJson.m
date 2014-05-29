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
    NSMutableArray *easyJsonConfig; // Contain the format of JSON files
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


#pragma mark - Base methods of JSON Parsing

// Analyze Array of objects
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

// Analyze one object
- (id)analyzeDictionary:(NSDictionary *)jsonDictionary forClass:(Class)objectClass
{
    // 1 - Find the config object for the specified class
    EJSEasyJsonObject *configObject = [self getConfigForClass:NSStringFromClass(objectClass)];
    
    // 2 - JSON values
    NSDictionary *jsonValues = jsonDictionary;
    if (EASY_JSON_ENVELOPE_WITH_OBJECT_NAME)
        jsonValues = [jsonDictionary objectForKey:configObject.classInfo.jsonKey];
    
    // 3 - NSManagedobject
    if (class_getSuperclass(objectClass) == [NSManagedObject class])
    {
        NSManagedObject *managedObject = [NSEntityDescription insertNewObjectForEntityForName:configObject.classInfo.attribute inManagedObjectContext:[EJSDatabaseManager sharedInstance].databaseCore.managedObjectContext];
        for (EJSEasyJsonParameterObject *parameter in configObject.parameters)
        {
            [self setPropertyForManagedObject:managedObject andParameter:parameter withJsonDict:jsonDictionary];

        }
        return managedObject;
    }
    // 3 - NSobject
    else
    {
        id object = [[objectClass alloc]init];
        for (EJSEasyJsonParameterObject *parameter in configObject.parameters)
        {
            [self setPropertyForObject:object andParameter:parameter withJsonDict:jsonDictionary];
        }
        return object;
    }
    return nil;
}


#pragma mark - Managed Object GET

// Get property description
- (NSPropertyDescription *)getPropertyDescriptionFromManagedObject:(NSManagedObject *)managedObject withParameter:(EJSEasyJsonParameterObject *)parameter andJsonDict:(NSDictionary *)jsonDict
{
    NSEntityDescription *entityDescription = [managedObject entity];
    NSPropertyDescription *propertyDescription;
    
    if ([self checkIfKey:parameter.jsonKey ExistIn:jsonDict]) {
        // Search concerned property
        for (NSString *propertyKey in [[entityDescription propertiesByName] allKeys]) {
            if ([propertyKey isEqual:parameter.attribute]) {
                propertyDescription = [[entityDescription propertiesByName] objectForKey:propertyKey];
                break;
            }
        }
    }
    return propertyDescription;
}

// Get formated parameter
- (id)getManagedObjectValueForParameter:(EJSEasyJsonParameterObject *)parameter propertyDescription:(NSPropertyDescription *)propertyDescription jsonDict:(NSDictionary *)jsonDict
{
    // Get the formated value or set
    if ([propertyDescription isKindOfClass:[NSAttributeDescription class]]) {
        NSString *jsonString = [jsonDict objectForKey:parameter.jsonKey];
        return [self returnFormatedAttributeValue:(NSAttributeDescription *)propertyDescription withJson:jsonString];
    } else if ([propertyDescription isKindOfClass:[NSRelationshipDescription class]]) {
        NSArray *jsonArray = [jsonDict objectForKey:parameter.jsonKey];
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

#pragma mark - Managed Object SET

// Set the managed object value
- (void)setPropertyForManagedObject:(NSManagedObject *)managedObject andParameter:(EJSEasyJsonParameterObject *)parameter withJsonDict:(NSDictionary *)jsonDict
{
    // A - Property description (Attribute or reliationship)
    NSPropertyDescription *propertyDescription = [self getPropertyDescriptionFromManagedObject:managedObject withParameter:parameter andJsonDict:jsonDict];
    if (propertyDescription)
    {
        // B - Formated value after json parsing
        id managedObjectValue = [self getManagedObjectValueForParameter:parameter propertyDescription:propertyDescription jsonDict:jsonDict];
        
        // C - Set Attribute
        if ((managedObjectValue) && (![managedObjectValue isKindOfClass:[NSSet class]]))
        {
            [managedObject setValue:managedObjectValue forKey:parameter.attribute];
        }
        // C - Set Relationship
        else if ((managedObjectValue) && ([managedObjectValue isKindOfClass:[NSSet class]]))
        {
            [managedObject setValue:managedObjectValue forKey:parameter.attribute];
        }
    }
}


#pragma mark - NSObject GET

// Get the type of property from NSObject according to the EasyJsonParameterObject
- (objc_property_t) getPropertyFromObject:(id)object withParameter:(EJSEasyJsonParameterObject *)parameter jsonDict:(NSDictionary *)jsonDict
{
    objc_property_t propertyResult = NULL;
    unsigned propertyCount;
    
    if ([self checkIfKey:parameter.jsonKey ExistIn:jsonDict])
    {
        // Each properties
        objc_property_t *objectProperties = class_copyPropertyList([object class], &propertyCount);
        for (int i = 0; i < propertyCount; i++)
        {
            // If Property corresponding with EasyJsonParameterObject
            if ([[NSString stringWithUTF8String:property_getName(objectProperties[i])] isEqual:parameter.attribute])
            {
                propertyResult = objectProperties[i];
                break;
            }
        }
    }
    return propertyResult;
}


#pragma mark - NSObject SET

// Get the value formated of specific property from JSON
- (void) setPropertyForObject:(id)object andParameter:(EJSEasyJsonParameterObject *)parameter withJsonDict:(NSDictionary *)jsonDict
{
    // Property
    objc_property_t property = [self getPropertyFromObject:object withParameter:parameter jsonDict:jsonDict];
    if (property)
    {
        NSString *jsonString = [jsonDict objectForKey:parameter.jsonKey];

        const char *propertyType = property_getAttributes(property);
        NSString *propertyKey = [NSString stringWithUTF8String:property_getName(property)];

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
            Class typeClass = [self classFromPropertyType:propertyType];
            
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
                    [object setValue:[self numberFormString:jsonString] forKey:propertyKey];
                }
                // NSData
                else if(typeClass == [NSData class]) {
                    [object setValue:[jsonString dataUsingEncoding:NSUTF8StringEncoding] forKey:propertyKey];
                }
            }
        }
    }
}


#pragma mark - Helper

- (BOOL)checkIfKey:(NSString *)key ExistIn:(NSDictionary *)dict
{
    if([dict objectForKey:key] != nil && [dict objectForKey:key] != [NSNull null])
        return YES;
    else
        return NO;
}


- (Class) classFromPropertyType:(const char*)propertyType
{
    NSString * typeString = [NSString stringWithUTF8String:propertyType];
    NSArray  * attributes = [typeString componentsSeparatedByString:@","];
    NSString * typeAttribute = [attributes objectAtIndex:0];
    NSString * typeClassName = [typeAttribute substringWithRange:NSMakeRange(3, [typeAttribute length]-4)];
    return NSClassFromString(typeClassName);
}

- (NSNumber *)numberFormString:(NSString *)stringNumber
{
    NSNumberFormatter *numFormatter = [[NSNumberFormatter alloc] init];
    [numFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    return [numFormatter numberFromString:stringNumber];
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
