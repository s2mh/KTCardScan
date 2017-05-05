//
//  KTCardEdgeDetector.m
//  CardScan
//
//  Created by QQQ on 2017/4/30.
//  Copyright © 2017年 KT. All rights reserved.
//

#import "KTCardEdgeDetector.h"

@interface KTCardEdgeDetector ()

@property (nonatomic) CGFloat topMaxY;
@property (nonatomic) CGFloat topMinY;
@property (nonatomic) CGFloat leftMaxX;
@property (nonatomic) CGFloat leftMinX;
@property (nonatomic) CGFloat bottomMaxY;
@property (nonatomic) CGFloat bottomMinY;
@property (nonatomic) CGFloat rightMaxX;
@property (nonatomic) CGFloat rightMinX;

@end

@implementation KTCardEdgeDetector

- (KTCardEdgeDetectorResult)detectWithLineArray:(GLfloat *)lineArray linesDetected:(NSUInteger)linesDetected {
    KTCardEdgeDetectorResult result = KTCardEdgeDetectorDidFindNone;

    NSInteger top = 0;
    NSInteger left = 0;
    NSInteger bottom = 0;
    NSInteger right = 0;
    
    for (NSUInteger i = 0; i < linesDetected; i++) {
        // y = kx + b;
        GLfloat k = lineArray[2 * i];
        GLfloat b = lineArray[2 * i + 1];
        
        if (k == 100000.0) {  // almost perpendicular x axis, b represents the interception on x axis
            CGFloat xInterception = b;
            if ((xInterception < self.leftMaxX) && (xInterception > self.leftMinX)) {
                result |= KTCardEdgeDetectorDidFindLeftEdge;
                left = 1;
            }
            
            if ((xInterception < self.rightMaxX) && (xInterception > self.rightMinX)) {
                result |= KTCardEdgeDetectorDidFindRightEdge;
                right = 1;
            }
        }
        
        if (k < 0.05 && k > -0.05) {  // almost perpendicular y axis
            CGFloat yInterception = b; // = 0 * x + b
            if ((yInterception < self.topMaxY) && (yInterception > self.topMinY)) {
                result |= KTCardEdgeDetectorDidFindTopEdge;
                top = 1;
            }
            
            if ((yInterception < self.bottomMaxY) && (yInterception > self.bottomMinY)) {
                result |= KTCardEdgeDetectorDidFindBottomEdge;
                bottom = 1;
            }
        }
        NSInteger edgeCount = top + left + bottom + right;
        if (edgeCount > 2) {
            result = KTCardEdgeDetectorDidFindAllEdges;
        }
    }
    
    return result;
}

- (void)setThreshold:(CGFloat)threshold {
    _threshold = threshold;
    _topMinY    = -1.0;
    _leftMinX   = -1.0;
    _bottomMaxY = 1.0;
    _rightMaxX  = 1.0;
    _topMaxY    = -threshold;
    _leftMaxX   = -threshold;
    _bottomMinY = threshold;
    _rightMinX  = threshold;
}

@end
