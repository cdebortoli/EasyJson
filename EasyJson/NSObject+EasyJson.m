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
            NSMutableArray *jsonArray = [[NSMutableArray alloc]init];
            for (id arrayObject in value) {
                NSDictionary *jsonArrayObjectDict = [arrayObject getJsonDictionary];
                if (jsonArrayObjectDict)
                    [jsonArray addObject:jsonArrayObjectDict];
            }
            [jsonDict setValue:jsonArray forKey:parameter.jsonKey];
        } else if ([value isKindOfClass:[NSDictionary class]]) {
            NSLog(@"rr");
        } else if((value != nil) && (propertyType[1] == '@')){
            [jsonDict setValue:value forKey:parameter.jsonKey];
        } else {
            if ([value intValue] != 0)
                [jsonDict setValue:value forKey:parameter.jsonKey];
        }
        
    }
    return jsonDict;
}

@end
