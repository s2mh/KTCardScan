//
//  KTScanOverlayView.h
//  CardScan
//
//  Created by QQQ on 2017/5/4.
//  Copyright © 2017年 KT. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface KTScanOverlayView : UIView

- (instancetype)initWithFrame:(CGRect)frame scanRect:(CGRect)scanRect;

@property (nonatomic) BOOL topEdgeVisible;
@property (nonatomic) BOOL leftEdgeVisible;
@property (nonatomic) BOOL bottomEdgeVisible;
@property (nonatomic) BOOL rightEdgeVisible;

@end
