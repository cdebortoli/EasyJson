//
//  Aircraft.h
//  EasyJson
//
//  Created by cdebortoli on 24/05/14.
//  Copyright (c) 2014 EJS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Airport, Pilot;

@interface Aircraft : NSManagedObject

@property (nonatomic, retain) NSNumber * canFly;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSDecimalNumber * primaryKey;
@property (nonatomic, retain) NSDate * purchaseDate;
@property (nonatomic, retain) Airport *airport;
@property (nonatomic, retain) Pilot *pilots;

@end
