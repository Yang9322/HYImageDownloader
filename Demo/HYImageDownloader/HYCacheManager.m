//
//  HYCacheManager.m
//  HYImageDownloader
//
//  Created by He yang on 2016/12/13.
//  Copyright © 2016年 He yang. All rights reserved.
//

#import "HYCacheManager.h"
#import "HYDiskCache.h"
#import "HYMemoryCache.h"
@interface HYCacheManager ()
@property (nonatomic,strong)HYMemoryCache *memoryCahce;
@property (nonatomic,strong)HYDiskCache *diskCache;

@end

@implementation HYCacheManager


+(id)sharedInstance{
    static HYCacheManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

-(instancetype)init{
    if (self = [super init]) {
        _memoryCahce = [[HYMemoryCache alloc] init];
        NSString *cachePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
        NSString *finalPath = [NSString stringWithFormat:@"%@/cacheManager.hy.cache",cachePath];
        _diskCache = [[HYDiskCache alloc] initWithPath:finalPath inlineThreshold:20];


        
    }
    return self;
}
-(void)setObject:(id)obj withKey:(NSString *)key{
    [_memoryCahce setObject:obj forKey:key];
    [_diskCache setObj:obj withKey:key];
}

-(id )objectForKey:(NSString *)key{
    id obj = [_memoryCahce objectForKey:key];
    if (obj) return obj;
    obj = [_diskCache objWithKey:key];
    return obj?:nil;
}

- (void)removeAll{
    [_diskCache removeAll];
}

@end
