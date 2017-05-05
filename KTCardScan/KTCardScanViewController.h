//
//  KTCardScanViewController.h
//  CardScan
//
//  Created by QQQ on 2017/4/28.
//  Copyright © 2017年 MY. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface KTCardScanViewController : UIViewController

@property (nonatomic, copy) void(^completion)(NSString *cardID, UIImage *cardImage);

@end
