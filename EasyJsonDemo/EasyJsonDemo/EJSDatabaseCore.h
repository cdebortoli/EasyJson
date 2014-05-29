#import <Foundation/Foundation.h>

@interface EJSDatabaseCore : NSObject

/*!
 @abstract Returns the managed object context for the application.
 */
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;

/*!
 @abstract Returns the managed object model for the application.
 */
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;

/*!
 @abstract Returns the persistent store coordinator for the application.
 */
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

/*!
 @abstract Returns the URL to the application's Documents directory.
 */
- (NSURL *)applicationLibrariesDirectory;

/*!
 @abstract Returns YES if "etlb.sqlite" exists, NO otherwise
 */
- (BOOL)databaseExist;

/*!
 @abstract Saves all modifications of the managed object context into the database
 */
- (BOOL)saveContext:(NSError *)error;

@end
