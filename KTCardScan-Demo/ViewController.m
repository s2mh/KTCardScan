//
//  ViewController.m
//  KTCardScan-Demo
//
//  Created by QQQ on 2017/5/5.
//  Copyright © 2017年 s2mh. All rights reserved.
//

#import "ViewController.h"
#import "KTCardScanViewController.h"

@interface ViewController ()

@property (strong, nonatomic) IBOutlet UILabel *cardIdLabel;
@property (strong, nonatomic) IBOutlet UIImageView *imageView;
@end

@implementation ViewController

- (IBAction)scan:(id)sender {
    self.cardIdLabel.text = @"Id Number";
    self.imageView.image = nil;
    
    KTCardScanViewController *vc = [[KTCardScanViewController alloc] init];
    vc.completion = ^(NSString *cardId, UIImage *cardImage) {
        self.cardIdLabel.text = cardId;
        self.imageView.image = cardImage;
    };
    [self.navigationController pushViewController:vc animated:YES];
}

@end
