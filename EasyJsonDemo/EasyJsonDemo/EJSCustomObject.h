//
//  EJSCustomObject.h
//  EasyJson
//
//  Created by cdebortoli on 25/05/14.
//  Copyright (c) 2014 EJS. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EJSCustomObject : NSObject

@property (strong, nonatomic) NSString *attrString;
@property (strong, nonatomic) NSDate *attrDate;
@property (strong, nonatomic) NSData *attrData;
@property (strong, nonatomic) NSNumber *attrNumber;
@property (assign, nonatomic) NSInteger attrInteger;
@property (assign, nonatomic) int attrInt;
@property (assign, nonatomic) float attrFloat;
@property (assign, nonatomic) double attrDouble;
@property (assign, nonatomic) BOOL attrBool;
@property (assign, nonatomic) long attrLong;
@property (strong, nonatomic) NSArray *attrArray;
@property (strong, nonatomic) NSDictionary *attrDictionary;

@end
