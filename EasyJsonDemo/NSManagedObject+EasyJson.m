//
//  NSManagedObject+EasyJson.m
//  EasyJsonDemo
//
//  Created by christophe on 31/05/14.
//  Copyright (c) 2014 cdebortoli. All rights reserved.
//

#import "NSManagedObject+EasyJson.h"
#import "EJSEasyJson.h"
#import "EJSEasyJsonObject.h"
#import "EJSEasyJsonParameterObject.h"

@implementation NSManagedObject (EasyJson)

- (NSDictionary *)getJsonDictionary
{
    NSMutableDictionary *jsonDict = [[NSMutableDictionary alloc]init];
    
    EJSEasyJsonObject *configObject = [[EJSEasyJson sharedInstance] getConfigForClass:NSStringFromClass([self class])];

    for (EJSEasyJsonParameterObject *parameter in configObject.parameters) {
        id value = [self valueForKey:parameter.attribute];

        if ((value != nil) && ([value isKindOfClass:[NSSet class]])) {
            NSMutableArray *relationArray = [[NSMutableArray alloc]init];
            for (NSManagedObject *relationManagedObject in value) {
                NSDictionary *jsonRelationDict = [relationManagedObject getJsonDictionary];
                if (jsonRelationDict)
                    [relationArray addObject:jsonRelationDict];
            }
            [jsonDict setValue:relationArray forKey:parameter.jsonKey];
        } else if(value != nil) {
            [jsonDict setValue:value forKey:parameter.jsonKey];
        }
    }
    
    #if (EASY_JSON_ENVELOPE_WITH_OBJECT_NAME)
        return @{configObject.classInfo.attribute: jsonDict};
    #endif
    return jsonDict;}

@end
