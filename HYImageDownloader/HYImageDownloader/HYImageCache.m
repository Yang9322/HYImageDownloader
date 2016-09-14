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


-(instancetype)init{
    self = [super init];
    if (self) {
        _dic = CFDictionaryCreateMutable(CFAllocatorGetDefault(), 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        _releaseOnMainThread = NO;
        _releaseAsynchronously = YES;
    }
    return self;

}


- (void)insertNodeAtHead:(_HYLinkedMapNode *)node{
   
    CFDictionarySetValue(_dic, (__bridge const void *)(node -> _key), (__bridge const void *)(node));
    _totalCost += node -> _cost;
    _totalCount ++;
    if (_head) {
        node -> _next = _head;
        _head -> _prev = node;
        _head = node;
    }else{
        _head = _tail = node;
    }
}


- (void)bringNodeToHead:(_HYLinkedMapNode *)node{
    if (_head == node) return;
    if (_tail == node) {
        _tail = node -> _prev;
        _tail -> _next = nil;
    }else{
        node -> _next ->_prev = node -> _prev;
        node -> _prev -> _next = node -> _next;
        
    }
    node -> _next = _head;
    node -> _prev = nil;
    _head -> _prev = node;
    _head = node;
}


- (_HYLinkedMapNode *)removeTailNode{
    if (!_tail) return nil;
    _HYLinkedMapNode *tail = _tail;
    CFDictionaryRemoveValue(_dic, (__bridge const void *)(_tail -> _key));
    _totalCost -= _tail -> _cost;
    _totalCount--;
    if (_head == tail) {
        _head = tail = nil;
    }else{
        _tail = _tail -> _prev;
        _tail ->_next = nil;
    }
    return tail;
}


- (void)removeNode:(_HYLinkedMapNode *)node{
    
    CFDictionaryRemoveValue(_dic, (__bridge const void *)(node -> _key));
    _totalCost -= node -> _cost;
    _totalCount --;
    if (node -> _next) node -> _next -> _prev = node -> _prev;
    if (node -> _prev) node -> _prev -> _next = node -> _next;
    if (_head == node) {
        _head = node -> _next;
    }
    if (_tail == node) {
        _tail = node -> _prev;
    }
}

- (void)removeAll{
    _totalCost = 0;
    _totalCount = 0;
    _head = nil;
    _tail = nil;
    if (CFDictionaryGetCount(_dic) > 0) {
        CFMutableDictionaryRef holder = _dic;
        _dic = CFDictionaryCreateMutable(CFAllocatorGetDefault(), 0, &kCFTypeDictionaryKeyCallBacks,&kCFTypeDictionaryValueCallBacks);
        if (_releaseAsynchronously) {
            dispatch_queue_t queue= _releaseOnMainThread ? dispatch_get_main_queue() : HYMemoryCacheReleaseQueue();
            dispatch_async(queue, ^{
                CFRelease(holder);
            });
        }else if (_releaseOnMainThread && !pthread_main_np()){
            dispatch_async(dispatch_get_main_queue(), ^{
                CFRelease(holder);
            });
        }else{
            CFRelease(holder);
        }
    }
    
}

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
    BOOL finish = NO;
    pthread_mutex_lock(&_lock);
    if (costLimit == 0) {
        [_lru removeAll];
        finish = YES;
    }else if (_lru -> _totalCost <= costLimit){
        finish = YES;
    }
    pthread_mutex_unlock(&_lock);
    if (finish) return;
    
    NSMutableArray *holder = [NSMutableArray array];
    while (!finish) {
        if (pthread_mutex_trylock(&_lock) == 0) {
            if (_lru -> _totalCost > costLimit) {
               _HYLinkedMapNode *node = [_lru removeTailNode];
                if (node) [holder addObject:node];
            }else{
                finish = YES;
            }
            pthread_mutex_unlock(&_lock);
        }else{
            usleep(10 * 1000); //sleep for 10ms
        }
    }
    
    if (holder.count) {
        dispatch_queue_t queue = _lru -> _releaseOnMainThread ? dispatch_get_main_queue() : HYMemoryCacheReleaseQueue();
        dispatch_async(queue, ^{
            [holder count];   //release in queue
        });
    }
}

- (void)_trimToCount:(NSUInteger)countLimit {
    BOOL finish = NO;
    pthread_mutex_lock(&_lock);
    if (countLimit == 0) {
        [_lru removeAll];
        finish = YES;
    }else if (_lru -> _totalCount <= countLimit){
        finish = YES;
    }
    pthread_mutex_unlock(&_lock);
    if (finish) return;
    NSMutableArray *holder = [NSMutableArray array];
    while (!finish) {
        if (pthread_mutex_trylock(&_lock) == 0) {
            if (_lru -> _totalCount > countLimit) {
                _HYLinkedMapNode *node = [_lru removeTailNode];
                if (node) [holder addObject:node];
            }else{
                finish = YES;
            }
            pthread_mutex_unlock(&_lock);
        }else{
            usleep(10 * 1000);
        }
    }
    if (holder.count) {
        dispatch_queue_t queue = _lru -> _releaseOnMainThread ? dispatch_get_main_queue() : HYMemoryCacheReleaseQueue();
        dispatch_async(queue, ^{
            [holder count];
        });
    }
    
}

- (void)_trimToAge:(NSTimeInterval)ageLimit {
    
    BOOL finish = NO;
    NSTimeInterval now = CACurrentMediaTime();
    pthread_mutex_lock(&_lock);
    if (ageLimit <= 0) {
        [_lru removeAll];
        finish = YES;
    }else if (!_lru -> _tail || (now - _lru -> _tail -> _time) <= ageLimit){
        finish = YES;
    }
    pthread_mutex_unlock(&_lock);
    if (finish) return;
    
    NSMutableArray *holder = [NSMutableArray array];
    while (!finish) {
        if (pthread_mutex_trylock(&_lock) == 0) {
            if (_lru ->  _tail && (now - _lru -> _tail -> _time) > ageLimit) {
                _HYLinkedMapNode *node = [_lru removeTailNode];
                if (node) [holder addObject:node];
            }else{
                finish = YES;
            }
            pthread_mutex_unlock(&_lock);
        }else{
            usleep(10 * 1000);
        }
    }
    
    if (holder.count) {
        dispatch_queue_t queue = _lru -> _releaseOnMainThread ? dispatch_get_main_queue() : HYMemoryCacheReleaseQueue();
        dispatch_async(queue, ^{
            [holder count]; // release in queue
        });
    }
}

- (BOOL)containsObjectForKey:(id)key {
    if (!key) return NO;
    pthread_mutex_lock(&_lock);
    BOOL contains = CFDictionaryContainsKey(_lru->_dic, (__bridge const void *)(key));
    pthread_mutex_unlock(&_lock);
    return contains;
}


-(void)setObject:(id)object forKey:(id)key{
    [self setObject:object forKey:key withCost:0];
}

-(void)setObject:(id)object forKey:(id)key withCost:(NSUInteger)cost{
    if (!key) return;
    if (!object) {
        [self removeObjectForKey:key];
        return;
    }
    pthread_mutex_lock(&_lock);
    _HYLinkedMapNode *node = CFDictionaryGetValue(_lru -> _dic, (__bridge const void *)(key));
    NSTimeInterval now = CACurrentMediaTime();
    if (node) {
        _lru -> _totalCost -= node ->_cost;
        _lru -> _totalCost += cost;
        node -> _cost = cost;
        node -> _time = now;
        node -> _value = object;
        [_lru bringNodeToHead:node];
    }else{
        node = [_HYLinkedMapNode new];
        node -> _cost = cost;
        node -> _time = now;
        node -> _key = key;
        node -> _value = object;
        [_lru insertNodeAtHead:node];
    }
    
    if (_lru -> _totalCost > -_costLimit) {
        
        dispatch_async(_queue, ^{
            [self trimToCost:_costLimit];
        });
    }
    
    
    if (_lru -> _totalCount > _countLimit) {
        _HYLinkedMapNode *node = [_lru removeTailNode];
        if (_lru -> _releaseAsynchronously) {
            dispatch_queue_t queue =_lru -> _releaseOnMainThread ? dispatch_get_main_queue() : HYMemoryCacheReleaseQueue();
            dispatch_async(queue, ^{
                [node class];
            });
            
        }else if (_lru -> _releaseOnMainThread && !pthread_main_np()){
            dispatch_async(dispatch_get_main_queue(), ^{
                [node class];
            });
        }
    }
    pthread_mutex_unlock(&_lock);
}

- (id)objectForKey:(id)key {
    if (!key) return nil;
    pthread_mutex_lock(&_lock);
    _HYLinkedMapNode *node = CFDictionaryGetValue(_lru->_dic, (__bridge const void *)(key));
    if (node) {
        node->_time = CACurrentMediaTime();
        [_lru bringNodeToHead:node];
    }
    pthread_mutex_unlock(&_lock);
    return node ? node->_value : nil;
}

-(void)removeObjectForKey:(id)key{
    if (!key) return;
    pthread_mutex_lock(&_lock);
    _HYLinkedMapNode *node = CFDictionaryGetValue(_lru -> _dic, (__bridge const void *)(key));
    if (node) {
        [_lru removeNode:node];
        if (_lru -> _releaseAsynchronously) {
            dispatch_queue_t queue = _lru -> _releaseOnMainThread ? dispatch_get_main_queue() : HYMemoryCacheReleaseQueue();
            dispatch_async(queue, ^{
                [node class];
            });
        }else if (_lru -> _releaseOnMainThread && !pthread_main_np()){
            dispatch_async(dispatch_get_main_queue(), ^{
                [node class];
            });
        }
    }
    pthread_mutex_unlock(&_lock);
}


-(void)removeAllObjects{
    pthread_mutex_lock(&_lock);
    [_lru removeAll];
    pthread_mutex_unlock(&_lock);
}

- (void)trimToCount:(NSUInteger)count {
    if (count == 0) {
        [self removeAllObjects];
        return;
    }
    [self _trimToCount:count];
}

- (void)trimToCost:(NSUInteger)cost {
    [self _trimToCost:cost];
}

- (void)trimToAge:(NSTimeInterval)age {
    [self _trimToAge:age];
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
        _diskCache = [[HYDiskCache alloc] init];
    }
    
    return self;
}

-(void)addImageForKey:(NSString *)URLIdentifier Image:(UIImage *)image{
  
    [_memoryCache setObject:image forKey:URLIdentifier];
    
}

-(UIImage *)imageWithKey:(NSString *)URLIdentifier{
    UIImage *image = [_memoryCache objectForKey:URLIdentifier];
    return image;
}


- (void)removeImageForKey:(NSString *)URLIdentifier{
    
    [_memoryCache removeObjectForKey:URLIdentifier];
}

- (void)removeAllImage{
    [_memoryCache removeAllObjects];
}





@end
