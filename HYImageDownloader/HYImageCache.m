//
//  HYImageCache.m
//  HYImageDownloader
//
//  Created by He yang on 16/5/2.
//  Copyright © 2016年 He yang. All rights reserved.
//

#import "HYImageCache.h"

@implementation HYImageCache

-(instancetype)init{
    return [self initWithMemoryCapacity:100 * 1024 *1024 preferredMemoryCapacity:60 * 1024 *1024];
}

-(instancetype)initWithMemoryCapacity:(UInt64)memoryCapacity preferredMemoryCapacity:(UInt64)preferredMemoryCapacity{
    if (self = [super init]) {
        
    }
    
    return self;
}

@end
