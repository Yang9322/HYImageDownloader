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
    
    [self hy_setImageWithURLString:URLString placeHolder:nil options:kNilOptions];
}

- (void)hy_setImageWithURLString:(NSString *)URLString placeHolder:(UIImage *)placeHolder options:(HYImageDowloaderOptions) options{
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:URLString]];
     [request addValue:@"image/*" forHTTPHeaderField:@"Accept"];
    
    [self hy_setImageWithRequest:request placeHolder:placeHolder options:options];
    
}


- (void)hy_setImageWithRequest:(NSURLRequest *)request placeHolder:(UIImage *)placeHolder options:(HYImageDowloaderOptions) options{
    
    [self cancelImageDownloadTask];
    
    if (!self.backgroundColor) {
        self.backgroundColor = [UIColor clearColor];
    }
    
    
    if (placeHolder) {
        if (options & HYImageDowloaderOptionRoundedRect) {
            self.image = [self adjustImageIfNeeded:placeHolder];
        }else{
            self.image = placeHolder;

        }

    }else{
        if (options & HYImageDowloaderOptionRoundedRect) {
            self.image =[self adjustImageIfNeeded:[UIImage imageNamed:@"timeline_image_placeholder"]];
        }else{
            self.image = [UIImage imageNamed:@"timeline_image_placeholder"];
        }
    }
    //判断request是否有效
    if (!request.URL) return;
    
    if ([self.activeReceipt.task.originalRequest.URL.absoluteString isEqualToString:request.URL.absoluteString]){
        return;
    }
    
     NSUUID *receiptID = [NSUUID UUID];
     HYImageDownloadReceipt *receipt = [[HYImageDownloader shareInstance] downloadImageForURLRequest:request withReceiptID:receiptID success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *responseObject) {

         if (options & HYImageDowloaderOptionFadeAnimation) {
             self.alpha = 0;
             UIImage *resizedImage = responseObject;
             if (options & HYImageDowloaderOptionFadeAnimation) {
                resizedImage = [self adjustImageIfNeeded:responseObject];
             }
             self.image = resizedImage;
             [UIView animateWithDuration:0.25 animations:^{
                 self.alpha = 1;
             }];
         }else{
             self.image = responseObject;
         }
         [self removeActiveReceipt];
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
        
        [self removeActiveReceipt];

    }];
    self.activeReceipt = receipt;
    
    
}

-(void)cancelImageDownloadTask{
    if (self.activeReceipt) {
        
        [[HYImageDownloader shareInstance] cancelTaskWithReceipt:self.activeReceipt];
        self.activeReceipt = nil;
    }
    
}


- (void)removeActiveReceipt{
   
    self.activeReceipt = nil;

}




#pragma mark HYImageRoundedRectOption

- (UIImage *)adjustImageIfNeeded:(UIImage *)image{
    if (self.bounds.size.width<= 0 || self.bounds.size.height <= 0 ) {
        return nil;
    }
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, 0, 0);

    UIImage *resizedImage  = nil;
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextAddPath(context, [self path]);
    CGContextClip(context);
    if (image && image.size.height && image.size.width){
        //ScaleAspectFill
        CGPoint center = CGPointMake(self.bounds.size.width * .5f, self.bounds.size.height * .5f);
        //Judge which is smaller,then shrink it
        CGFloat scaleW = image.size.width  / self.bounds.size.width;
        CGFloat scaleH = image.size.height / self.bounds.size.height;
        CGFloat scale = scaleW < scaleH ? scaleW : scaleH;
        CGSize  size = CGSizeMake(image.size.width / scale, image.size.height / scale);
        CGRect  drawRect = CGRectWithCenterAndSize(center, size);

        CGContextTranslateCTM(context, 0, self.bounds.size.height);
        CGContextScaleCTM(context, 1.0, -1.0);
        CGContextDrawImage(context, drawRect, image.CGImage);
        
        resizedImage = UIGraphicsGetImageFromCurrentImageContext();
        
    }
    UIGraphicsEndImageContext();

    return resizedImage;

}

- (CGPathRef)path
{
    return [[UIBezierPath bezierPathWithRoundedRect:self.bounds
                                       cornerRadius:CGRectGetWidth(self.bounds) / 2] CGPath];
}

CGRect CGRectWithCenterAndSize(CGPoint center, CGSize size){

    return CGRectMake(center.x - (size.width / 2), center.y - (size.height / 2), size.width, size.height);
}




@end
