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

@property (nonatomic,assign)NSInteger sizeLimit;

@property (nonatomic,assign)NSTimeInterval ageLimit;

@property (nonatomic,assign)NSInteger currentSize;

@end

@implementation HYDiskCache


-(instancetype)initWithPath:(NSString *)path inlineThreshold:(NSUInteger)threshold{
    self = [super init];
    if (self) {
        if (path.length) {
            NSError *error;
            BOOL success = [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error];
            if (!success) {
                NSAssert(0, @"init cache path failed");
                return nil;
            }

            _path = path;
            _queue = dispatch_queue_create("com.yang.cache.disk", DISPATCH_QUEUE_SERIAL);
            _lock = dispatch_semaphore_create(1);
            _sizeLimit = 10 *1000 *1000;
            _currentSize = [[NSUserDefaults standardUserDefaults] objectForKey:@"com.yang.cache.currentSize"] ? [[[NSUserDefaults standardUserDefaults] objectForKey:@"com.yang.cache.currentSize"] integerValue] : 0;
            
            [self _trimInBackground];
        }
    }
    return self;
}


- (void)_trimInBackground{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(60 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self _trimSize:_sizeLimit];
        [self _trimAge:_ageLimit];
        [self _trimInBackground];
    });
}


- (void)_trimSize:(NSInteger)sizeLimit{
    
}

- (void)_trimAge:(NSTimeInterval)ageLimit{
    
}

-(void)setObj:(id)obj withKey:(NSString *)key{
    if (!key) return;
    if (obj) {
        NSData *data = nil;
        Lock();

        data = [NSKeyedArchiver archivedDataWithRootObject:obj];
     
        if (data.length) {
            NSString *finalPath = [self generatefilenameWithkey:key];
            [data writeToFile:finalPath atomically:NO];
            }
            
        Unlock();

   
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

- (void)removeAll{
    
    dispatch_async(_queue, ^{
        [[NSFileManager defaultManager] removeItemAtPath:_path error:NULL];

    });

}


- (NSString *)generatefilenameWithkey:(NSString *)key{
    NSString *keyStr = [key stringByReplacingOccurrencesOfString:@"/" withString:@""];
    NSString *finalPath = [_path stringByAppendingString:[NSString stringWithFormat:@"/%@",keyStr]];
    return finalPath;
}



@end
