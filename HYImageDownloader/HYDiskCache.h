//
//  HYDiskCache.h
//  HYImageDownloader
//
//  Created by heyang on 16/9/13.
//  Copyright © 2016年 He yang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HYDiskCache : NSObject

- (instancetype)initWithPath:(NSString *)path
             inlineThreshold:(NSUInteger)threshold;

- (void)addImageForKey:(NSString *)key Image:(UIImage *)image;

-(UIImage *)imageWithKey:(NSString *)key;

@end
