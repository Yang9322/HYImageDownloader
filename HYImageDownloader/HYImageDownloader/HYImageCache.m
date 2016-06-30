//
//  HYImageCache.m
//  HYImageDownloader
//
//  Created by He yang on 16/5/2.
//  Copyright © 2016年 He yang. All rights reserved.
//

#import "HYImageCache.h"
#import <CoreFoundation/CoreFoundation.h>
#import <pthread.h>

static inline dispatch_queue_t HYMemoryCacheReleaseQueue(){
    return dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
}

@interface _HYLinkedMapNode : NSObject {
    @package
    __unsafe_unretained _HYLinkedMapNode *_prev; // retained by dic
    __unsafe_unretained _HYLinkedMapNode *_next; // retained by dic
    id _key;
    id _value;
    NSUInteger _cost;
    NSTimeInterval _time;
}
@end

@implementation _HYLinkedMapNode
@end


@interface _HYLinkedMap : NSObject {
    @package
    CFMutableDictionaryRef _dic; // do not set object directly
    NSUInteger _totalCost;
    NSUInteger _totalCount;
    _HYLinkedMapNode *_head; // MRU, do not change it directly
    _HYLinkedMapNode *_tail; // LRU, do not change it directly
    BOOL _releaseOnMainThread;
    BOOL _releaseAsynchronously;
}
@end

@implementation _HYLinkedMap



@end

@implementation HYMemoryCache{
    pthread_mutex_t _lock;
    _HYLinkedMap *_lru;
    dispatch_queue_t _queue;
}

- (instancetype)init{
    if (self = [super init]) {
    pthread_mutex_init(&_lock, NULL);
        _lru = [_HYLinkedMap new];
        _queue = dispatch_queue_create("com.yang.cache.memory", DISPATCH_QUEUE_SERIAL);
        _countLimit = NSUIntegerMax;
        _costLimit = NSUIntegerMax;
        _ageLimit = DBL_MAX;
        _autoTrimInterval = 5.0;
        _shouldRemoveAllObjectsOnMemoryWarning = YES;
        _shouldRemoveAllObjectsWhenEnteringBackground = YES;
        [self _trimRecursively];
        
    }
    return self;
}

- (void)_trimRecursively{
    __weak typeof (self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(_autoTrimInterval * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        [self _trimInBackground];
        [self _trimRecursively];

    });
}


- (void)_trimInBackground{
    
    dispatch_async(_queue, ^{
        [self _trimToCost:self->_costLimit];
        [self _trimToCount:self->_countLimit];
        [self _trimToAge:self->_ageLimit];
    });
}


- (void)_trimToCost:(NSUInteger)costLimit{
    
}

- (void)_trimToCount:(NSUInteger)countLimit {

}

- (void)_trimToAge:(NSTimeInterval)ageLimit {

}

@end




@interface HYImageCache ()
@property (nonatomic,strong)NSMutableDictionary *cachedImages;
@property (nonatomic,strong)dispatch_queue_t synchorinizationQueye;

@end

@implementation HYImageCache


//  为了后续的磁盘缓存做准备
-(instancetype)init{
    return [self initWithMemoryCapacity:100 * 1024 * 1024 preferredMemoryCapacity:60 * 1024 * 1024];
}

-(instancetype)initWithMemoryCapacity:(UInt64)memoryCapacity preferredMemoryCapacity:(UInt64)preferredMemoryCapacity{
    if (self = [super init]) {
        _memoryCache = [[HYMemoryCache alloc] init];
    }
    
    return self;
}

-(void)addImageForKey:(NSString *)URLIdentifier Image:(UIImage *)image{
    dispatch_barrier_sync(_synchorinizationQueye, ^{
        self.cachedImages[URLIdentifier] = image;
    });
    
}

-(UIImage *)imageWithKey:(NSString *)URLIdentifier{
    __block UIImage *image = nil;
    dispatch_barrier_sync(_synchorinizationQueye, ^{
        image = self.cachedImages[URLIdentifier];
    });
    return image;
}


- (void)removeImageForKey:(NSString *)URLIdentifier{
    dispatch_barrier_sync(_synchorinizationQueye, ^{
        [self.cachedImages removeObjectForKey:URLIdentifier];
    });
}

- (void)removeAllImage{
    dispatch_barrier_sync(_synchorinizationQueye, ^{
        [self.cachedImages removeAllObjects];
    });
}


@end
