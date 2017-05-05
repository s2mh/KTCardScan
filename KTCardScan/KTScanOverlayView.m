//
//  KTScanOverlayView.m
//  CardScan
//
//  Created by QQQ on 2017/5/4.
//  Copyright © 2017年 KT. All rights reserved.
//

#import "KTScanOverlayView.h"

@interface KTScanOverlayView ()

@property (nonatomic) CGRect scanRect;
@property (nonatomic) CGRect edgeLineRect;
@property (nonatomic) CGFloat edgeLineWidth;

@end

@implementation KTScanOverlayView

- (instancetype)initWithFrame:(CGRect)frame scanRect:(CGRect)scanRect
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        
        self.scanRect = scanRect;
        self.edgeLineWidth = 10.0f;
        self.edgeLineRect = CGRectInset(self.scanRect, (self.edgeLineWidth / 2.0), (self.edgeLineWidth / 2.0));
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    CGContextRef context = UIGraphicsGetCurrentContext();
    if (!CGRectEqualToRect(rect, self.scanRect)) {
        CGContextSetFillColorWithColor(context, [[UIColor colorWithWhite:0 alpha:0.35] CGColor]);
        CGContextFillRect(context, rect);
        CGContextClearRect(context, self.scanRect);
    }
    
    // left landscape state
    if (self.rightEdgeVisible) {
        CGContextMoveToPoint(context, CGRectGetMaxX(self.scanRect), CGRectGetMinY(self.edgeLineRect));
        CGContextAddLineToPoint(context, CGRectGetMinX(self.scanRect), CGRectGetMinY(self.edgeLineRect));
    }
    if (self.topEdgeVisible) {
        CGContextMoveToPoint(context, CGRectGetMinX(self.edgeLineRect), CGRectGetMinY(self.scanRect));
        CGContextAddLineToPoint(context, CGRectGetMinX(self.edgeLineRect), CGRectGetMaxY(self.scanRect));
    }
    if (self.leftEdgeVisible) {
        CGContextMoveToPoint(context, CGRectGetMinX(self.scanRect), CGRectGetMaxY(self.edgeLineRect));
        CGContextAddLineToPoint(context, CGRectGetMaxX(self.scanRect), CGRectGetMaxY(self.edgeLineRect));
    }
    if (self.bottomEdgeVisible) {
        CGContextMoveToPoint(context, CGRectGetMaxX(self.edgeLineRect), CGRectGetMaxY(self.scanRect));
        CGContextAddLineToPoint(context, CGRectGetMaxX(self.edgeLineRect), CGRectGetMinY(self.scanRect));
    }
    CGContextSetLineWidth(context, self.edgeLineWidth);
    CGContextSetStrokeColorWithColor(context, [UIColor orangeColor].CGColor);
    CGContextStrokePath(context);
}

- (void)setTopEdgeVisible:(BOOL)topEdgeVisible {
    if (topEdgeVisible != _topEdgeVisible) {
        _topEdgeVisible = topEdgeVisible;
        [self setNeedsDisplayInRect:_scanRect];
    }
}

- (void)setLeftEdgeVisible:(BOOL)leftEdgeVisible {
    if (leftEdgeVisible != _leftEdgeVisible) {
        _leftEdgeVisible = leftEdgeVisible;
        [self setNeedsDisplayInRect:_scanRect];
    }
}

- (void)setBottomEdgeVisible:(BOOL)bottomEdgeVisible {
    if (bottomEdgeVisible != _bottomEdgeVisible) {
        _bottomEdgeVisible = bottomEdgeVisible;
        [self setNeedsDisplayInRect:_scanRect];
    }
}

- (void)setRightEdgeVisible:(BOOL)rightEdgeVisible {
    if (rightEdgeVisible != _rightEdgeVisible) {
        _rightEdgeVisible = rightEdgeVisible;
        [self setNeedsDisplayInRect:_scanRect];
    }
}

@end
