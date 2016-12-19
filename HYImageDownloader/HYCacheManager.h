//
//  HYCacheManager.h
//  HYImageDownloader
//
//  Created by He yang on 2016/12/13.
//  Copyright © 2016年 He yang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HYCacheManager : NSObject



+(id)sharedInstance;

- (void)setObject:(id)obj withKey:(NSString *)key;

- (id)objectForKey:(NSString *)key;


@end
