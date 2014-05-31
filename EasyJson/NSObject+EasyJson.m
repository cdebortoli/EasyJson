//
//  NSObject+EasyJson.m
//  EasyJsonDemo
//
//  Created by christophe on 31/05/14.
//  Copyright (c) 2014 cdebortoli. All rights reserved.
//

#import "NSObject+EasyJson.h"
#import "EJSEasyJson.h"
#import "EJSEasyJsonObject.h"
#import "EJSEasyJsonParameterObject.h"
#import "EJSEasyJsonClassObject.h"

@implementation NSObject (EasyJson)

- (NSDictionary *)getJsonDictionary
{
    NSMutableDictionary *jsonDict = [[NSMutableDictionary alloc]init];
   
    EJSEasyJsonObject *configObject = [[EJSEasyJson sharedInstance] getConfigForClass:NSStringFromClass([self class])];

    for (EJSEasyJsonParameterObject *parameter in configObject.parameters) {
        objc_property_t property = [[EJSEasyJson sharedInstance] getPropertyFromObject:self withParameter:parameter];
        const char *propertyType = property_getAttributes(property);

        id value = [self valueForKey:parameter.attribute];
        
        if ([value isKindOfClass:[NSArray class]]) {
            NSMutableArray *jsonArrayParameter = [[NSMutableArray alloc]init];
            for (id arrayObject in value) {
                NSDictionary *jsonOccurenceDict = [arrayObject getJsonDictionary];
                if (jsonOccurenceDict)
                    [jsonArrayParameter addObject:jsonOccurenceDict];
            }
            [jsonDict setValue:jsonArrayParameter forKey:parameter.jsonKey];
        } else if ([value isKindOfClass:[NSDictionary class]]) {
            // Dictionary
            NSMutableDictionary *jsonDictParameter = [[NSMutableDictionary alloc]init];
            for (NSString *key in [value allKeys]) {
                NSDictionary *jsonOccurenceDict = [[value objectForKey:key] getJsonDictionary];
                if (jsonOccurenceDict)
                    [jsonDictParameter setValue:jsonOccurenceDict forKey:key];
            }
            [jsonDict setValue:jsonDictParameter forKey:parameter.jsonKey];
        } else if((value != nil) && (propertyType[1] == '@')) { // String
            [jsonDict setValue:value forKey:parameter.jsonKey];
        } else if ([value isKindOfClass:[NSNumber class]]) { // Number or primitive
            [jsonDict setValue:value forKey:parameter.jsonKey];
        }
    }
    #if (EASY_JSON_ENVELOPE_WITH_OBJECT_NAME)
        return @{configObject.classInfo.attribute: jsonDict};
    #endif
    return jsonDict;
}

@end
