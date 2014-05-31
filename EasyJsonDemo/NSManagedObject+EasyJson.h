//
//  NSManagedObject+EasyJson.h
//  EasyJsonDemo
//
//  Created by christophe on 31/05/14.
//  Copyright (c) 2014 cdebortoli. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface NSManagedObject (EasyJson)

- (NSDictionary *)getJsonDictionary;

@end
