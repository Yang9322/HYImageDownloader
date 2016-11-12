//
//  HYImageCache.h
//  HYImageDownloader
//
//  Created by He yang on 16/5/2.
//  Copyright © 2016年 He yang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HYDiskCache.h"


@interface HYMemoryCache :NSObject
@property (nonatomic, copy) NSString *name;

@property (nonatomic,readonly) NSUInteger totalCount;

@property (nonatomic,readonly) NSUInteger totalCost;

@property (nonatomic,assign) NSUInteger countLimit;

@property (nonatomic,assign) NSUInteger costLimit;

@property (nonatomic,assign) NSTimeInterval ageLimit;

@property (nonatomic,assign)NSTimeInterval autoTrimInterval;

@property (nonatomic,assign) BOOL shouldRemoveAllObjectsOnMemoryWarning;

@property (nonatomic,assign)BOOL shouldRemoveAllObjectsWhenEnteringBackground;

@property (nonatomic, copy) void(^didReceiveMemoryWarningBlock)(HYMemoryCache *cache);

@property (nonatomic, copy) void(^didEnterBackgroundBlock)(HYMemoryCache *cache);

@property (nonatomic,assign)BOOL releaseOnMainThread;

@property (nonatomic,assign)BOOL releaseAsynchronously;

- (BOOL)containsObjectForKey:(id)key;

- (id)objectForKey:(id)key;

- (void)setObject:(id)object forKey:(id)key;

- (void)setObject:(id)object forKey:(id)key withCost:(NSUInteger)cost;

- (void)removeObjectForKey:(id)key;

- (void)removeAllObjects;

- (void)trimToCount:(NSUInteger)count;

- (void)trimToCost:(NSUInteger)cost;

- (void)trimToAge:(NSTimeInterval)age;


@end


@protocol HYImageCache <NSObject>

- (void)addImageForKey:(NSString *)URLIdentifier Image:(UIImage *)image;

- (UIImage *)imageWithKey:(NSString *)URLIdentifier;

- (void)removeImageForKey:(NSString *)URLIdentifier;

- (void)removeAllImage;


@end

@interface HYImageCache : NSObject<HYImageCache>

@property (nonatomic,strong)HYMemoryCache *memoryCache;

@property (nonatomic,strong)HYDiskCache *diskCache;

@property (nonatomic,assign) UInt64 memoryCapacity;

@property (nonatomic,assign)UInt64 preferredCapacity;

- (instancetype)init;




@end
