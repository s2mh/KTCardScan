//
//  KTCardEdgeDetector.h
//  CardScan
//
//  Created by QQQ on 2017/4/30.
//  Copyright © 2017年 KT. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_OPTIONS(NSUInteger, KTCardEdgeDetectorResult) {
    KTCardEdgeDetectorDidFindNone        = 0,
    KTCardEdgeDetectorDidFindTopEdge     = 1 << 0,
    KTCardEdgeDetectorDidFindLeftEdge    = 1 << 1,
    KTCardEdgeDetectorDidFindBottomEdge  = 1 << 2,
    KTCardEdgeDetectorDidFindRightEdge   = 1 << 3,
    KTCardEdgeDetectorDidFindAllEdges    = 0xf,
};

@interface KTCardEdgeDetector : NSObject

@property (nonatomic) CGFloat threshold;

- (KTCardEdgeDetectorResult)detectWithLineArray:(GLfloat *)lineArray linesDetected:(NSUInteger)linesDetected;

@end
