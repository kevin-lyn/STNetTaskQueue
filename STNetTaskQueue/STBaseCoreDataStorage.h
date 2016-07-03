//
//  STBaseCoreDataStorage.h
//  STNetTaskQueue
//
//  Created by Oleg Sorochich on 7/3/16.
//  Copyright © 2016 Sth4Me. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface STBaseCoreDataStorage : NSObject

@property (atomic, copy, readonly) NSString *storeName;

@property (readonly, strong, nonatomic) NSManagedObjectModel *model;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *coordinator;
@property (readonly, strong, nonatomic) NSManagedObjectContext *mainContext;

- (instancetype)initWithStoreName:(NSString *)storeName;

- (NSArray *)recordsWithName:(NSString *)name predicate:(NSPredicate *)predicate;
- (id)insertObjectWithClass:(Class)objectClass;
- (void)deleteRecords:(NSArray *)records;

- (id)executeBlockInPrivate:(id(^)())block;
- (id)executeBlockInMain:(id(^)())block;

- (void)save;

@end
