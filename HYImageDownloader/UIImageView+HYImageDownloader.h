//
//  UIImageView+HYImageDownloader.h
//  HYImageDownloader
//
//  Created by He yang on 16/5/1.
//  Copyright © 2016年 He yang. All rights reserved.
//


#import <UIKit/UIKit.h>


typedef NS_ENUM(NSInteger,HYImageDowloaderOptions) {
    HYImageDownloaderOptionNone = 0,//Default no option
    HYImageFadeAnimation = 1,//When download image successfully,add a fade animation to image
   //......
};

@interface UIImageView (HYImageDownloader)


- (void)hy_setImageWithURLString:(NSString *)URLString;


- (void)hy_setImageWithURLString:(NSString *)URLString placeHolder:(UIImage *)placeHolder options:(HYImageDowloaderOptions) options;


- (void)hy_setImageWithRequest:(NSURLRequest *)request placeHolder:(UIImage *)placeHolder options:(HYImageDowloaderOptions) options;


@end
