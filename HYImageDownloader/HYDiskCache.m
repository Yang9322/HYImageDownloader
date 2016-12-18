//
//  HYDiskCache.m
//  HYImageDownloader
//
//  Created by heyang on 16/9/13.
//  Copyright © 2016年 He yang. All rights reserved.
//

#import "HYDiskCache.h"

#define Lock() dispatch_semaphore_wait(self->_lock, DISPATCH_TIME_FOREVER)
#define Unlock() dispatch_semaphore_signal(self->_lock)

@interface HYDiskCache ()

@property (nonatomic,strong)dispatch_queue_t queue;

@property (nonatomic,copy)NSString *path;

@property (nonatomic,strong)dispatch_semaphore_t lock;

@end

@implementation HYDiskCache


-(instancetype)initWithPath:(NSString *)path inlineThreshold:(NSUInteger)threshold{
    self = [super init];
    if (self) {
        if (path.length) {
            NSError *error;
            BOOL success = [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error];
            if (!success) {
                NSLog(@"init cache path failed at%@",error);
                return nil;
            }
            _path = path;
            _queue = dispatch_queue_create("com.yang.cache.disk", DISPATCH_QUEUE_SERIAL);
            _lock = dispatch_semaphore_create(1);
            
        }
    }
    return self;
}

-(void)setObj:(id)obj withKey:(NSString *)key{
    
    if (obj) {
        NSData *data = nil;
       
        @try {
            data = [NSKeyedArchiver archivedDataWithRootObject:obj];
        } @catch (NSException *exception) {
            
        }
        dispatch_async(_queue, ^{
            if (data.length) {
                NSString *finalPath = [self generatefilenameWithkey:key];
                [data writeToFile:finalPath atomically:NO];

            }
            id obj = [self objWithKey:key];
            
        });
   
    }else{
        [self removeObjForKey:key];
    }


}

-(id)objWithKey:(NSString *)key{
    Lock();
    NSString *finalPath = [self generatefilenameWithkey:key];
    id obj = [NSKeyedUnarchiver unarchiveObjectWithFile:finalPath];
    Unlock();
    
    return obj ?: nil;
}


- (id)removeObjForKey:(NSString *)key{
    if (!key.length) return nil;
    Lock();
    NSString *finalPath = [self generatefilenameWithkey:key];
    id obj = [NSKeyedUnarchiver unarchiveObjectWithFile:finalPath];
    [[NSFileManager defaultManager] removeItemAtPath:finalPath error:NULL];
    Unlock();
    return obj?:nil;
}


- (NSString *)generatefilenameWithkey:(NSString *)key{
    NSString *keyStr = [key stringByReplacingOccurrencesOfString:@"/" withString:@""];
    NSString *finalPath = [_path stringByAppendingString:[NSString stringWithFormat:@"/%@",keyStr]];
    return finalPath;
}



@end
