//
//  Airport.h
//  EasyJson
//
//  Created by cdebortoli on 24/05/14.
//  Copyright (c) 2014 EJS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Aircraft;

@interface Airport : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * primaryKey;
@property (nonatomic, retain) Aircraft *aircrafts;

@end
