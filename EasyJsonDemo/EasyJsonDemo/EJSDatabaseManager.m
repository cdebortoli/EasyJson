#import "EJSDatabaseManager.h"

@implementation EJSDatabaseManager

static EJSDatabaseManager __strong *sharedInstance = nil;

#pragma mark - Init

+(EJSDatabaseManager *)sharedInstance
{
    static dispatch_once_t pred;
    dispatch_once(&pred, ^{
        sharedInstance = [[EJSDatabaseManager alloc]init];
    });
    return sharedInstance;
}

-(id)init
{
    self = [super init];
    if (self != nil)
    {
        self.databaseCore = [[EJSDatabaseCore alloc] init];
        
    }
    return self;
}

-(void)dealloc
{
}

#pragma mark - Save and rollback

-(BOOL)saveContext:(NSError *)error
{
    return [self.databaseCore saveContext:error];
}

-(void)rollback
{
    [self.databaseCore.managedObjectContext rollback];
}

@end
