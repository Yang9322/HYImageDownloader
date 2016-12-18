//
//  HYDiskCache.m
//  HYImageDownloader
//
//  Created by heyang on 16/9/13.
//  Copyright © 2016年 He yang. All rights reserved.
//

#import "HYDiskCache.h"

@implementation HYDiskCache


-(instancetype)initWithPath:(NSString *)path inlineThreshold:(NSUInteger)threshold{
    self = [super init];
    if (self) {
        if (path.length) {
            NSError *error;
            BOOL success = [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error];
            if (!success) {
                NSLog(@"init cache path failed at%@",error);
                return nil;
            }
            
            NSLog(@" begin---%@---end",path);

        }
    }
    return self;
}

-(void)setObj:(id)obj withKey:(NSString *)key{
    


}

-(id)objWithKey:(NSString *)key{
    
    
    return nil;
}

@end
