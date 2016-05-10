//
//  UIImageView+HYImageDownloader.m
//  HYImageDownloader
//
//  Created by He yang on 16/5/1.
//  Copyright © 2016年 He yang. All rights reserved.
//

#import "UIImageView+HYImageDownloader.h"

#import "HYImageDownloader.h"

#import "objc/runtime.h"

@interface UIImageView (_HYImageDownloader)

@property (nonatomic,strong)HYImageDownloadReceipt *activeReceipt;

@end

@implementation UIImageView (_HYImageDownloader)


-(void)setActiveReceipt:(HYImageDownloadReceipt *)activeReceipt{
    objc_setAssociatedObject(self, @selector(activeReceipt), activeReceipt, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

-(HYImageDownloadReceipt *)activeReceipt{
  return objc_getAssociatedObject(self, @selector(activeReceipt));
}

@end



@implementation UIImageView (HYImageDownloader)

- (void)hy_setImageWithURLString:(NSString *)URLString{
    
    [self hy_setImageWithURLString:URLString placeHolder:nil];
}

- (void)hy_setImageWithURLString:(NSString *)URLString placeHolder:(UIImage *)placeHolder{
    
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:URLString]];
     [request addValue:@"image/*" forHTTPHeaderField:@"Accept"];
    [self hy_setImageWithRequest:request placeHolder:placeHolder];
    
}


-(void)hy_setImageWithRequest:(NSURLRequest *)request placeHolder:(UIImage *)placeHolder{
    
    
    if (placeHolder) self.image = placeHolder;
    //判断request是否有效
    if (!request.URL) return;
    
    if ([self.activeReceipt.task.originalRequest.URL.absoluteString isEqualToString:request.URL.absoluteString]){
        return;
    }
    
     NSUUID *receiptID = [NSUUID UUID];
     HYImageDownloadReceipt *receipt = [[HYImageDownloader shareInstance] downloadImageForURLRequest:request withReceiptID:receiptID success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *responseObject) {
         
         self.image = responseObject;
         [self removeActiveReceipt];
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
        
        [self removeActiveReceipt];

    }];
    self.activeReceipt = receipt;
    
    
}


- (void)removeActiveReceipt{
   
    self.activeReceipt = nil;

}





@end
