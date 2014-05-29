//
//  Pilot.h
//  EasyJson
//
//  Created by cdebortoli on 24/05/14.
//  Copyright (c) 2014 EJS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Aircraft;

@interface Pilot : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * primaryKey;
@property (nonatomic, retain) NSSet *aircrafts;
@end

@interface Pilot (CoreDataGeneratedAccessors)

- (void)addAircraftsObject:(Aircraft *)value;
- (void)removeAircraftsObject:(Aircraft *)value;
- (void)addAircrafts:(NSSet *)values;
- (void)removeAircrafts:(NSSet *)values;

@end
