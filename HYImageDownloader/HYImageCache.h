//
//  HYImageCache.h
//  HYImageDownloader
//
//  Created by He yang on 16/5/2.
//  Copyright © 2016年 He yang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@protocol HYImageCache <NSObject>

- (void)addImageForKey:(NSString *)URLIdentifier Image:(UIImage *)image;

- (UIImage *)imageWithKey:(NSString *)URLIdentifier;

- (void)removeImageForKey:(NSString *)URLIdentifier;


@end

@interface HYImageCache : NSObject<HYImageCache>

@property (nonatomic,assign) UInt64 memoryCapacity;

@property (nonatomic,assign)UInt64 preferredCapacity;

- (instancetype)init;




@end
