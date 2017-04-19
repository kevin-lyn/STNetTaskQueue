//
//  STBaseCoreDataStorage.m
//  STNetTaskQueue
//
//  Created by Oleg Sorochich on 7/3/16.
//  Copyright © 2016 Sth4Me. All rights reserved.
//

#import "STBaseCoreDataStorage.h"

@interface STBaseCoreDataStorage () {
    @private
    void *_queueTag;
}

@property (atomic, copy, readwrite) NSString *storeName;

@property (readwrite, strong, nonatomic) NSManagedObjectModel *model;
@property (readwrite, strong, nonatomic) NSPersistentStoreCoordinator *coordinator;

@property (readwrite, strong, nonatomic) NSManagedObjectContext *mainContext;
@property (nonatomic, weak) NSManagedObjectContext *currentContext;
@property (nonatomic, strong) NSManagedObjectContext *privateContext;

@property (nonatomic, strong) dispatch_queue_t privateQueue;


@end

@implementation STBaseCoreDataStorage

#pragma mark - Initialization

- (instancetype)initWithStoreName:(NSString *)storeName {
    self = [super init];
 
    if (self) {
        self.storeName = storeName;
       
        [self setUpQueue];
        [self setUpModel];
        [self setUpCoordinator];
        [self setUpMainContext];
        [self setUpPrivateContext];
        
        self.currentContext = self.privateContext;
    }
    
    return self;
}

#pragma mark - Public interface

- (NSArray *)recordsWithName:(NSString*)name predicate:(NSPredicate*)predicate {
    return [self executeBlock:^() {
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:name inManagedObjectContext:_currentContext];
        [fetchRequest setEntity:entity];
        fetchRequest.predicate = predicate;

        NSArray *records = [_currentContext executeFetchRequest:fetchRequest error:nil];
        return records;
    }];
}

- (id)insertObjectWithClass:(Class)objectClass {
    return [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass(objectClass)
                                         inManagedObjectContext:_currentContext];
}

- (void)deleteRecords:(NSArray *)records {
    for(NSManagedObject* record in records) {
        [_currentContext deleteObject:record];
    }
}

- (id)executeBlockInPrivate:(id(^)())block {
    
    @synchronized(self) {
        __block id result;
        dispatch_sync(_privateQueue, ^() {
            @autoreleasepool {
                result = block();
            }
        });
        return result;
    }
}

- (id)executeBlockInMain:(id(^)())block {
    
    @synchronized(self) {
        _currentContext = _mainContext;
        id result = block();
        _currentContext = _privateContext;
        return result;
    }
}

- (void)save {
    
    NSError* error = nil;
    [_currentContext save:&error];
    NSAssert(error == nil, @"saving error: %@", error);
}

#pragma mark - Private interface

- (id)executeBlock:(id(^)())block {
    
    __block id result;
    
    dispatch_sync(_privateQueue, ^() {
        @autoreleasepool {
            result = block();
        }
    });
    return result;
}

- (void)setUpQueue {
    self.privateQueue = dispatch_queue_create([_storeName cStringUsingEncoding:NSUTF8StringEncoding], DISPATCH_QUEUE_CONCURRENT);
    _queueTag = &_queueTag;
    dispatch_queue_set_specific(_privateQueue, _queueTag, _queueTag, NULL);
}

- (void)setUpMainContext {
    if (_mainContext != nil) {
        return;
    }
    if (_coordinator != nil) {
        _mainContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [_mainContext setPersistentStoreCoordinator:_coordinator];
    }
}

- (void)setUpPrivateContext {
    
    if (_privateContext != nil) {
        return;
    }
    if (_coordinator != nil) {
        _privateContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        [_privateContext setPersistentStoreCoordinator:_coordinator];
    }
}

- (void)setUpModel {
    
    [self executeBlock:^() {
        if (_model != nil) {
            return (id)nil;
        }
        
        NSBundle *bundle = [NSBundle bundleForClass:[self classForCoder]];
        
        NSURL *modelURL = [bundle URLForResource:_storeName withExtension:@"momd"];
        if(modelURL == nil) {
            modelURL = [bundle URLForResource:_storeName withExtension:@"mom"];
        }
        _model = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
        return (id)nil;
    }];
}

- (void)setUpCoordinator {
    
    [self executeBlock:^() {
        if (_coordinator != nil) {
            return (id)nil;
        }
        NSURL *storeURL = [[self applicationDocumentsDirectory]
                           URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.sqlite", self.storeName]];
        NSError *error = nil;
        _coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:_model];
        if (![_coordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
            NSAssert(NO, @"Unresolved error %@, %@", error, [error userInfo]);
        }
        return (id)nil;
    }];
}

- (NSURL *)applicationDocumentsDirectory {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
