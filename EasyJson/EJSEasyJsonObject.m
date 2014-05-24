//
//  EJSEasyJsonObject.m
//  EasyJson
//
//  Created by cdebortoli on 23/05/14.
//  Copyright (c) 2014 EJS. All rights reserved.
//

#import "EJSEasyJsonObject.h"

@implementation EJSEasyJsonObject

- (id)init
{
    self = [super init];
    if (self) {
        self.parameters = [[NSMutableArray alloc] init];
    }
    return self;
}

@end
