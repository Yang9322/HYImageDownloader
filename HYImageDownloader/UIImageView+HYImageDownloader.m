//
//  UIImageView+HYImageDownloader.m
//  HYImageDownloader
//
//  Created by He yang on 16/5/1.
//  Copyright © 2016年 He yang. All rights reserved.
//

#import "UIImageView+HYImageDownloader.h"

#import "HYImageDownloader.h"
@implementation UIImageView (HYImageDownloader)

- (void)hy_setImageWithURLString:(NSString *)URLString{
    
    [self hy_setImageWithURLString:URLString placeHolder:nil];
}

- (void)hy_setImageWithURLString:(NSString *)URLString placeHolder:(UIImage *)placeHolder{
    NSURL *url = [NSURL URLWithString:URLString];
    
    NSLog(@" begin---%@---end",url );

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:URLString]];
    [request addValue:@"image/*" forHTTPHeaderField:@"Accept"];
    [self hy_setImageWithRequest:request placeHolder:placeHolder];
    
}


-(void)hy_setImageWithRequest:(NSURLRequest *)request placeHolder:(UIImage *)placeHolder{
   //判断request是否有效
    if (placeHolder) {
        self.image = placeHolder;
    }

    if (!request.URL) {
        return;
    }
    
    //判断该imageView是否已经处于下载状态
    NSUUID *receiptID = [NSUUID UUID];
     HYImageDownloadReceipt *receipt = [[HYImageDownloader shareInstance] downloadImageForURLRequest:request withReceiptID:receiptID success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *responseObject) {
         
         self.image = responseObject;
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
        
        
    }];
    
   
    if (receipt) {
        
        
    }
    
}





@end
