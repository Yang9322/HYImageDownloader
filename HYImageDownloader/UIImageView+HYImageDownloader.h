//
//  UIImageView+HYImageDownloader.h
//  HYImageDownloader
//
//  Created by He yang on 16/5/1.
//  Copyright © 2016年 He yang. All rights reserved.
//


#import <UIKit/UIKit.h>


#import "HYImageDownloader.h"


@interface UIImageView (HYImageDownloader)


- (void)hy_setImageWithURLString:(NSString *)URLString;


- (void)hy_setImageWithURLString:(NSString *)URLString placeHolder:(UIImage *)placeHolder options:(HYImageDownloaderOptions) options;


- (void)hy_setImageWithURLString:(NSString *)URLString placeHolder:(UIImage *)placeHolder options:(HYImageDownloaderOptions) options withCompletionBlock:(void (^) (UIImage *image,NSError *error))completion;


- (void)hy_setImageWithRequest:(NSURLRequest *)request placeHolder:(UIImage *)placeHolder options:(HYImageDownloaderOptions) options;


- (void)hy_setImageWithRequest:(NSURLRequest *)request placeHolder:(UIImage *)placeHolder options:(HYImageDownloaderOptions) options withCompletionBlock:(void (^) (UIImage *image,NSError *error))completion;


- (void)cancelImageDownloadTask;

@end
