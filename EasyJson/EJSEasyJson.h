//
//  EJSEasyJson.h
//  EasyJson
//
//  Created by cdebortoli on 23/05/14.
//  Copyright (c) 2014 EJS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

#define EASY_JSON_ENVELOPE_WITH_OBJECT_NAME 0
#define EASY_JSON_DATE_FORMAT @"yyyy-MM-dd"

@class EJSEasyJsonObject, EJSEasyJsonParameterObject;
@interface EJSEasyJson : NSObject

+ (EJSEasyJson *)sharedInstance;

@property (strong, nonatomic) NSMutableArray *easyJsonConfig; // Contain the format of JSON files

- (NSArray *)analyzeArray:(NSArray *)jsonArray forClass:(Class)objectClass;
- (id)analyzeDictionary:(NSDictionary *)jsonDictionary forClass:(Class)objectClass;

- (EJSEasyJsonObject *)getConfigForClass:(NSString *)className;
- (objc_property_t) getPropertyFromObject:(id)object withParameter:(EJSEasyJsonParameterObject *)parameter;

@end
