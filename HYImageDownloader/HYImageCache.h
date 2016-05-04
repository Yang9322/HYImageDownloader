//
//  HYImageCache.h
//  HYImageDownloader
//
//  Created by He yang on 16/5/2.
//  Copyright © 2016年 He yang. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol HYImageCache <NSObject>



@end

@interface HYImageCache : NSObject<HYImageCache>

- (instancetype)init;

@end
