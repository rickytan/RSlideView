//
//  RSlideView+PrivateMethods.h
//  DongMan
//
//  Created by sheng tan on 12-4-4.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "RSlideView.h"

@interface RSlideView (PrivateMethods)
- (void)onPageControlValueChange:(id)sender;
- (void)loadNeededPages;
- (void)loadViewOfPageAtIndex:(NSInteger)index;
- (void)collectReusableViews;
- (void)clearUpandMakeReusableAtIndex:(NSInteger)index;
- (void)updateScrollViewOffset;
- (void)adjustScrollViewOffsetToSinglePage;
- (void)updateVisibalePages;
- (void)updateContentSize;
- (void)longPressGestureHandler:(UILongPressGestureRecognizer*)longPress;
- (void)tapGestureHandler:(UITapGestureRecognizer*)tap;
- (void)panGestureHandler:(UIPanGestureRecognizer*)pan;
- (void)didReceiveMemoryWarning:(NSNotification*)notification;
@end
