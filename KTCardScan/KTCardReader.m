//
//  KTCardReader.m
//  CardScan
//
//  Created by QQQ on 2017/5/2.
//  Copyright © 2017年 KT. All rights reserved.
//

#import "KTCardReader.h"
#import <TesseractOCR/TesseractOCR.h>

static const NSUInteger cardIdStingLength = 18;

@interface KTCardReader ()

@property (nonatomic, strong) NSOperationQueue *operationQueue;

@end

@implementation KTCardReader

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.operationQueue = [[NSOperationQueue alloc] init];
    }
    return self;
}

- (void)readCardIdFromImage:(UIImage *)image completion:(void (^)(NSString *cardId, UIImage *image))completion {
    G8RecognitionOperation *operation = [[G8RecognitionOperation alloc] initWithLanguage:@"chi_sim_idn"];
    operation.tesseract.engineMode = G8OCREngineModeTesseractOnly;
    operation.tesseract.pageSegmentationMode = G8PageSegmentationModeAutoOnly;
    CGFloat cardWidth  = image.size.width;
    CGFloat cardHeight = image.size.height;
    
    CGFloat x = 0.0;
    CGFloat y = ceil(cardHeight * 0.8);
    operation.tesseract.image = image;
    operation.tesseract.rect = CGRectMake(x , y, (cardWidth - x), (cardHeight - y));

    operation.recognitionCompleteBlock = ^(G8Tesseract *tesseract){
        NSString *cardId = nil;
        UIImage *cardImage = nil;
        
        NSArray<NSString *> *recognizedTexts = [tesseract.recognizedText componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        __block NSString *possibleCardId = nil;
        __block NSInteger firstCharacterLocation = 0;
        [recognizedTexts enumerateObjectsUsingBlock:^(NSString *recognizedText, NSUInteger idx, BOOL * _Nonnull stop) {
            if (recognizedText.length == cardIdStingLength) {
                possibleCardId = recognizedText;
                *stop = YES;
            } else {
                firstCharacterLocation += recognizedText.length;
            }
        }];
        __block BOOL accurate = (possibleCardId.length == cardIdStingLength);
        if (accurate) {
            NSArray<NSArray *> *characterChoicesArray = [tesseract characterChoices];
            [characterChoicesArray enumerateObjectsUsingBlock:^(NSArray<G8RecognizedBlock *> *characterChoices, NSUInteger idx, BOOL * _Nonnull stop) {
                if ((idx < firstCharacterLocation) || (idx > (firstCharacterLocation + 18))) {
                    return;
                }
                if (characterChoices.count > 1) {
                    accurate = NO;
                    *stop = YES;
                }
                [characterChoices enumerateObjectsUsingBlock:^(G8RecognizedBlock * characterChoice, NSUInteger idx, BOOL * _Nonnull stop1) {
                    static const CGFloat confidenceThreshold = 52.0f;
                    if (characterChoice.confidence < confidenceThreshold) {
                        accurate = NO;
                        *stop = YES;
                    }
                }];
            }];
        }
        if (accurate) {
            cardId = possibleCardId;
            cardImage = image;
        }
        
        if (completion) {
            completion(cardId, cardImage);
        }
    };
    [self.operationQueue addOperation:operation];
}

- (void)dealloc
{
    [G8Tesseract clearCache];
}

@end
