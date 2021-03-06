//
//  UIImageView+HYImageDownloader.m
//  HYImageDownloader
//
//  Created by He yang on 16/5/1.
//  Copyright © 2016年 He yang. All rights reserved.
//

#import "UIImageView+HYImageDownloader.h"


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


NSString *const ImageFadeAnimationKey = @"HYImageFade";

@implementation UIImageView (HYImageDownloader)

- (void)hy_setImageWithURLString:(NSString *)URLString{
    
    [self hy_setImageWithURLString:URLString placeHolder:nil options:kNilOptions];
}

- (void)hy_setImageWithURLString:(NSString *)URLString placeHolder:(UIImage *)placeHolder options:(HYImageDownloaderOptions) options{
    
   
    
    [self hy_setImageWithURLString:URLString placeHolder:placeHolder options:options withCompletionBlock:nil];
}

-(void)hy_setImageWithURLString:(NSString *)URLString placeHolder:(UIImage *)placeHolder options:(HYImageDownloaderOptions)options withCompletionBlock:(void (^)(UIImage *, NSError *))completion{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:URLString]];
    [request addValue:@"image/*" forHTTPHeaderField:@"Accept"];
    [self hy_setImageWithRequest:request placeHolder:placeHolder options:options withCompletionBlock:completion];
 
}

- (void)hy_setImageWithRequest:(NSURLRequest *)request placeHolder:(UIImage *)placeHolder options:(HYImageDownloaderOptions) options{

    [self hy_setImageWithRequest:request placeHolder:placeHolder options:options withCompletionBlock:nil];
}


- (void)hy_setImageWithRequest:(NSURLRequest *)request placeHolder:(UIImage *)placeHolder options:(HYImageDownloaderOptions) options withCompletionBlock:(void (^)(UIImage *, NSError *))completion{
    
    //判断request是否有效
    if (!request.URL) return;
    
    if ([self.activeReceipt.task.originalRequest.URL.absoluteString isEqualToString:request.URL.absoluteString]){
        return;
    }
    
    
    [self cancelImageDownloadTask];
    
    if (!self.backgroundColor) {
        self.backgroundColor = [UIColor clearColor];
    }
    
    if (!self.highlighted) {
        [self.layer removeAnimationForKey:ImageFadeAnimationKey];
    }
    
    
    if (placeHolder) {
        if (options & HYImageDownloaderOptionRoundedRect) {
            [self adjustImageIfNeeded:placeHolder withCompletionBlock:^(UIImage *destiImage) {
                self.image = destiImage;
            }];
        }else{
            self.image = placeHolder;

        }

    }
 
     NSUUID *receiptID = [NSUUID UUID];
     HYImageDownloadReceipt *receipt = [[HYImageDownloader shareInstance] downloadImageForURLRequest:request withReceiptID:receiptID success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *responseObject){

         if (options & HYImageDownloaderOptionFadeAnimation) {
             UIImage *resizedImage = responseObject;
             if (options & HYImageDownloaderOptionRoundedRect) {
                [self adjustImageIfNeeded:resizedImage withCompletionBlock:^(UIImage *destiImage) {
                    self.image = destiImage;
                completion?completion(resizedImage,nil):nil;

                }];
             }else{
                 self.image = resizedImage;
                 completion?completion(resizedImage,nil):nil;

             }
             CATransition *transition = [CATransition animation];
             transition.duration = 0.25f;
             transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
             transition.type = kCATransitionFade;
             [self.layer addAnimation:transition forKey:ImageFadeAnimationKey];
             
         }else if(options & HYImageDownloaderOptionRoundedRect){
             [self adjustImageIfNeeded:responseObject withCompletionBlock:^(UIImage *destiImage) {
                 self.image = destiImage;
                 completion?completion(destiImage,nil):nil;

             }];
         }else{
             self.image = responseObject;
             completion?completion(responseObject,nil):nil;

         }
         [self removeActiveReceipt];
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
        
        [self removeActiveReceipt];
        completion(nil,error);

    } options:options];
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


- (void)adjustImageIfNeeded:(UIImage *)image withCompletionBlock:(void (^) (UIImage *destiImage))completion{
    if (self.bounds.size.width<= 0 || self.bounds.size.height <= 0 ) {
        return ;
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
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
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(resizedImage);
        });
    });
}

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
