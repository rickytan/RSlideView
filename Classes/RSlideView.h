//
//  RSlideView.h
//  DongMan
//
//  Created by sheng tan on 12-4-4.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RSlideView;
@class RPageControl;

@protocol RPageControlDelegate, RPageControlDataSource;

@protocol RPageControlDataSource <NSObject>
@optional
- (NSString*)pageControlTitleForPage:(NSInteger)index;

@end

@protocol RPageControlDelegate <NSObject>
@optional
- (void)pageControlDidChangePage:(RPageControl*)pageControl;

@end

typedef NS_ENUM(NSInteger, RPageControlTitleAlignment) {
    RPageControllTitleAlignLeft = 0,
    RPageControllTitleAlignRight
};

@interface RPageControl : UIView {
@private
    UILabel                     *_titleLabel;
    UIPageControl               *_pageControl;
}

@property (nonatomic, strong) NSString *title;
@property (nonatomic, weak) id<RPageControlDataSource> dataSource;
@property (nonatomic, weak) id<RPageControlDelegate> delegate;
@property (nonatomic, assign) RPageControlTitleAlignment titleAlignment;
@property (nonatomic, assign) NSInteger numberOfPages;
@property (nonatomic, assign) NSInteger currentPage;


- (void)setNumberOfPages:(NSInteger)numberOfPages;
- (void)setCurrentPage:(NSInteger)currentPage;

@end

@protocol RSlideViewDelegate <NSObject>
@optional
- (void)RSlideView:(RSlideView*)slideView tapOnPageAtIndex:(NSInteger)index;
- (void)RSlideView:(RSlideView *)slideView doubleTapOnPageAtIndex:(NSInteger)index;

- (void)RSlideView:(RSlideView*)sliderView didScrollAtPageOffset:(CGFloat)pageOffset;
- (void)RSlideViewDidEndScrollAnimation:(RSlideView *)sliderView;
@end

@protocol RSlideViewDataSource <NSObject>
@required
- (NSInteger)RSlideViewNumberOfPages;
- (UIView*)RSlideView:(RSlideView*)slideView 
    viewForPageAtIndex:(NSInteger)index;

@optional
- (NSString*)RSlideView:(RSlideView*)slideView titleForPageAtIndex:(NSInteger)index;
@end

IB_DESIGNABLE
@interface RSlideView : UIView 
<UIScrollViewDelegate,
RPageControlDataSource,
RPageControlDelegate,
UIGestureRecognizerDelegate> {
    NSInteger                   _totalPages;
    NSInteger                   _currentPage;
    
    NSInteger                   _visibleNumberOfViewsPerPage;   // Should always be a odd number
    NSInteger                   _extraPagesForLoopShow;
    
    BOOL                        _allowScrollToPage;

    
    NSMutableArray             *_reusableViews;
    
    NSInteger                   _selectedPageIndex;
}

@property (nonatomic, weak) IBOutlet id<RSlideViewDelegate> delegate;
@property (nonatomic, weak) IBOutlet id<RSlideViewDataSource> dataSource;

@property (nonatomic, readonly, strong) RPageControl * pageControl;
@property (nonatomic, readonly, strong) UIScrollView * scrollView;
@property (nonatomic, readonly, assign) NSInteger      currentPage;

@property (nonatomic, assign, getter = isLoopSlide) IBInspectable BOOL loopSlide;
@property (nonatomic, assign, getter = isContinuousScroll) IBInspectable BOOL continuousScroll;
@property (nonatomic, assign, getter = isPageControlHidden) IBInspectable BOOL pageControlHidden;   // Default YES
@property (nonatomic, assign) IBInspectable UIColor *pageControlBackgroundColor;

@property (nonatomic, assign) IBInspectable CGSize pageSize;  // Default to be the RSlideView's size

    // The Gap between two pages, default to be 0
@property (nonatomic, assign) IBInspectable CGFloat pageMargin;

@property (nonatomic, assign) IBInspectable RPageControlTitleAlignment pageTitleAlignment;

- (void)reloadData;
- (UIView*)dequeueReusableView;
- (UIView*)viewOfPageAtIndex:(NSInteger)index;
- (NSInteger)indexOfPageView:(UIView*)view;
- (void)scrollToPageAtIndex:(NSInteger)index;   // Scroll to a page, e.g 1 ... n
- (void)scrollToPageOffset:(CGFloat)pageOffset; // Scroll to a offset, can be 1.25

- (void)previousPage;
- (void)nextPage;

- (void)setPageControlHidden:(BOOL)pageControlHidden 
                    animated:(BOOL)animated;

- (CGRect)pageControlRectForBounds:(CGRect)rect;
@end

