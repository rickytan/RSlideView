//
//  RSlideView.h
//  DongMan
//
//  Created by sheng tan on 12-4-4.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RSlideView;

@protocol RSlideViewDelegate <NSObject>
@optional
- (void)RSlideView:(RSlideView*)slideView tapStartOnPageAtIndex:(NSInteger)index;
- (void)RSlideView:(RSlideView*)slideView tapEndOnPageAtIndex:(NSInteger)index;
- (void)RSlideView:(RSlideView *)slideView doubleTapOnPageAtIndex:(NSInteger)index;
@end

@protocol RSlideViewDataSource <NSObject>
@required
- (NSInteger)RSlideViewNumberOfPages;
- (UIView*)RSlideView:(RSlideView*)slideView 
    viewForPageAtIndex:(NSInteger)index;
@optional
- (NSString*)RSlideView:(RSlideView*)slideView titleForPageAtIndex:(NSInteger)index;
@end

@interface RSlideView : UIView 
<UIScrollViewDelegate> {
    NSInteger                   _totalPages;
    NSInteger                   _currentPage;
    
    CGFloat                     _scrollWidth;
    NSInteger                   _visibleNumberOfViewsPerPage;   // Should always be a odd number
    
    NSMutableArray             *_reusableViews;
    
    UIView                     *_firstView;
    UIView                     *_lastView;
    
    UIScrollView               *_scrollView;
    UIPageControl              *_pageControl;
}

@property (nonatomic, assign) id<RSlideViewDelegate> delegate;
@property (nonatomic, assign) id<RSlideViewDataSource> dataSource;

@property (nonatomic, readonly) UIPageControl *pageControl;
@property (nonatomic, readonly) UIScrollView *scrollView;
@property (nonatomic, assign, getter = isLoopSlide) BOOL loopSlide;
@property (nonatomic, assign, getter = isContinuousScroll) BOOL continuousScroll;
@property (nonatomic, assign, getter = isPageControlHidden) BOOL pageControlHidden;
@property (nonatomic) CGSize pageSize;  // Default to be the RSlideView's size

    // The Gap between two pages, default to be 0
@property (nonatomic) CGFloat pageMargin;

- (void)reloadData;
- (UIView*)dequeueReusableView;
- (UIView*)viewOfPageAtIndex:(NSInteger)index;
- (void)scrollToPageAtIndex:(NSInteger)index;

- (void)previousPage;
- (void)nextPage;

- (void)setPageControlHidden:(BOOL)pageControlHidden 
                    animated:(BOOL)animated;
@end
