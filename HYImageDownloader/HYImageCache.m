//
//  HYImageCache.m
//  HYImageDownloader
//
//  Created by He yang on 16/5/2.
//  Copyright © 2016年 He yang. All rights reserved.
//

#import "HYImageCache.h"

@interface HYImageCache ()
@property (nonatomic,strong)NSMutableDictionary *cachedImages;
@property (nonatomic,strong)dispatch_queue_t synchorinizationQueye;

@end

@implementation HYImageCache

-(instancetype)init{
    return [self initWithMemoryCapacity:100 * 1024 * 1024 preferredMemoryCapacity:60 * 1024 * 1024];
}

-(instancetype)initWithMemoryCapacity:(UInt64)memoryCapacity preferredMemoryCapacity:(UInt64)preferredMemoryCapacity{
    if (self = [super init]) {
        
        _memoryCapacity = memoryCapacity;
        _preferredCapacity = preferredMemoryCapacity;
        _cachedImages = [NSMutableDictionary dictionary];
        _synchorinizationQueye = dispatch_queue_create([@"cacheQueue.heyang.com" cStringUsingEncoding:NSASCIIStringEncoding], DISPATCH_QUEUE_CONCURRENT);
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
