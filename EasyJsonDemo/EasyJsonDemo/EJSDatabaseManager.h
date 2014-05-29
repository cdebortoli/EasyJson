#import <Foundation/Foundation.h>
#import "EJSDatabaseCore.h"


@interface EJSDatabaseManager : NSObject

@property(nonatomic, strong) EJSDatabaseCore *databaseCore;


#pragma mark - Init

/*!
 @abstract Returns the instance of the Database Manager if created, else creating it
 */
+(EJSDatabaseManager *)sharedInstance;



#pragma mark - Save and rollback

/*!
 @abstract calls the context saving method of the DB Manager
 */
- (BOOL)saveContext:(NSError *)error;

/*!
 @abstract Cancels modifications applied to the Managed Object Context
 */
- (void)rollback;


@end
