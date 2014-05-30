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

- (NSArray *)analyzeArray:(NSArray *)jsonArray forClass:(Class)objectClass;
- (id)analyzeDictionary:(NSDictionary *)jsonDictionary forClass:(Class)objectClass;

@end
