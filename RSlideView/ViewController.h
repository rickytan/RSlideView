//
//  ViewController.h
//  RSlideView
//
//  Created by sheng tan on 12-4-7.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RSlideView.h"

@interface ViewController : UIViewController
<RSlideViewDelegate,RSlideViewDataSource>
{
    RSlideView              * slideView;
}

- (IBAction)onPrev:(id)sender;
- (IBAction)onNext:(id)sender;
- (IBAction)onLoopscroll:(id)sender;
- (IBAction)onContinuousscroll:(id)sender;
@end
