//
//  UIImageView+HYImageDownloader.h
//  HYImageDownloader
//
//  Created by He yang on 16/5/1.
//  Copyright © 2016年 He yang. All rights reserved.
//


#import <UIKit/UIKit.h>


typedef NS_OPTIONS(NSInteger,HYImageDowloaderOptions) {
    HYImageDownloaderOptionNone = 1 << 0,//Default no option
    HYImageFadeAnimationOption = 1 << 2,//When download image successfully,add a fade animation to image
    HYImageRoundedRectOption = 1 << 3, //When download image successfully,clip the imageView with cornerRadius
   //To be continued ...
};

@interface UIImageView (HYImageDownloader)


- (void)hy_setImageWithURLString:(NSString *)URLString;


- (void)hy_setImageWithURLString:(NSString *)URLString placeHolder:(UIImage *)placeHolder options:(HYImageDowloaderOptions) options;


- (void)hy_setImageWithRequest:(NSURLRequest *)request placeHolder:(UIImage *)placeHolder options:(HYImageDowloaderOptions) options;

- (void)cancelImageDownloadTask;

@end
