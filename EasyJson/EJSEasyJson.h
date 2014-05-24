//
//  EJSEasyJson.h
//  EasyJson
//
//  Created by cdebortoli on 23/05/14.
//  Copyright (c) 2014 EJS. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EJSEasyJson : NSObject

+ (EJSEasyJson *)sharedInstance;

- (NSArray *)analyzeArray:(NSArray *)jsonArray forClass:(id)objectClass;
- (id)analyzeDictionary:(NSDictionary *)jsonDictionary forClass:(id)objectClass;


// 1: Check if array or dictionary
    // If array : Loop. For each object, if dictionary, analyse.
    // If dictionary : Analyse

// 2: Check type.
    // Init nsmanagedobject or object. id object = [[NSClassFromString(@"NameofClass") alloc] init];
    // Set parameters from json
    // Check each type

// 3: return object


@end
