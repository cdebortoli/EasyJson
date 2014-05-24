//
//  EJSEasyJsonObject.h
//  EasyJson
//
//  Created by cdebortoli on 23/05/14.
//  Copyright (c) 2014 EJS. All rights reserved.
//

#import <Foundation/Foundation.h>

@class EJSEasyJsonClassObject;
@interface EJSEasyJsonObject : NSObject

@property (strong, nonatomic) EJSEasyJsonClassObject *classInfo;
@property (strong, nonatomic) NSMutableArray *parameters;

@end
