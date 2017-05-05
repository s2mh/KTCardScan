//
//  KTCardReader.h
//  CardScan
//
//  Created by QQQ on 2017/5/2.
//  Copyright © 2017年 KT. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface KTCardReader : NSObject

- (void)readCardIdFromImage:(UIImage *)image completion:(void (^)(NSString *cardId, UIImage *image))completion;

@end
