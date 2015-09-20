//
//  SADataManager+Status.m
//  fansky
//
//  Created by Zzy on 9/12/15.
//  Copyright (c) 2015 Zzy. All rights reserved.
//

#import "SADataManager+Status.h"
#import "SADataManager+Photo.h"
#import "SADataManager+User.h"
#import "NSString+Utils.h"

@implementation SADataManager (Status)

static NSString *const ENTITY_NAME = @"SAStatus";

- (void)insertStatusWithObjects:(NSArray *)objects type:(SAStatusTypes)type
{
    SAUser *currentUser = [SADataManager sharedManager].currentUser;
    [objects enumerateObjectsUsingBlock:^(id object, NSUInteger idx, BOOL *stop) {
        [self insertStatusWithObject:object localUser:currentUser type:type];
    }];
}

- (SAStatus *)insertStatusWithObject:(id)object localUser:(SAUser *)localUser type:(SAStatusTypes)type
{
    NSString *statusID = [object objectForKey:@"id"];
    NSString *source = [object objectForKey:@"source"];
    NSString *text = [object objectForKey:@"text"];
    NSString *createdAtString = [object objectForKey:@"created_at"];
    NSString *repostStatusID = [object objectForKey:@"repost_status_id"];
    NSDate *createdAt = [createdAtString dateWithDefaultFormat];
    
    SAPhoto *photo = [[SADataManager sharedManager] insertPhotoWithObject:[object objectForKey:@"photo"]];
    SAUser *user = [[SADataManager sharedManager] insertOrUpdateUserWithObject:[object objectForKey:@"user"] local:NO active:NO token:nil secret:nil];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:ENTITY_NAME];
    fetchRequest.fetchLimit = 1;
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"statusID = %@", statusID];
    
    __block NSError *error;
    __block SAStatus *resultStatus;
    [self.managedObjectContext performBlockAndWait:^{
        NSArray *fetchResult = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
        if (!error && fetchResult && fetchResult.count) {
            SAStatus *existStatus = [fetchResult firstObject];
            existStatus.type = @(type | existStatus.type.integerValue);
            resultStatus = existStatus;
        } else {
            [self.managedObjectContext performBlockAndWait:^{
                SAStatus *status = [NSEntityDescription insertNewObjectForEntityForName:ENTITY_NAME inManagedObjectContext:self.managedObjectContext];
                status.statusID = statusID;
                status.source = source;
                status.text = text;
                status.photo = photo;
                status.user = user;
                status.repostStatusID = repostStatusID;
                status.createdAt = createdAt;
                status.localUser = localUser;
                status.type = @(type | status.type.integerValue);
                resultStatus = status;
            }];
        }
    }];
    return resultStatus;
}

- (SAStatus *)statusWithID:(NSString *)statusID
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:ENTITY_NAME];
    fetchRequest.fetchLimit = 1;
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"statusID = %@", statusID];
    
    __block NSError *error;
    __block SAStatus *resultStatus;
    [self.managedObjectContext performBlockAndWait:^{
        NSArray *fetchResult = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
        if (!error && fetchResult && fetchResult.count) {
            SAStatus *existStatus = [fetchResult firstObject];
            resultStatus = existStatus;
        }
    }];
    return resultStatus;
}

@end
