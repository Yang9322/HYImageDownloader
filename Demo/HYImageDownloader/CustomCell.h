//
//  CustomCell.h
//  HYImageDownloader
//
//  Created by He yang on 2016/12/23.
//  Copyright © 2016年 He yang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CustomCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *customImageView;
@property (copy,nonatomic)NSString *markString;
@end
