//
//  RSlideView.h
//  DongMan
//
//  Created by sheng tan on 12-4-4.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RSlideView;
@class RPageControll;


@protocol RPageControllDataSource <NSObject>
@optional
- (NSString*)RPageControllTitleForPage:(NSInteger)index;

@end

@protocol RPageControllDelegate <NSObject>
@optional
- (void)RPageControllDidChangePage:(RPageControll*)pageControl;

@end

typedef enum {
    RPageControllTitleAlignLeft = 0,
    RPageControllTitleAlignRight
}RPageControlTitleAlignment;

@interface RPageControll : UIView {
@private
    UILabel                     *_titleLabel;
    UIPageControl               *_pageControl;
}

@property (nonatomic, assign) NSString *title;
@property (nonatomic, assign) id<RPageControllDataSource> dataSource;
@property (nonatomic, assign) id<RPageControllDelegate> delegate;
@property (nonatomic, assign) RPageControlTitleAlignment titleAlignment;
@property (nonatomic, assign) CGFloat dotMargin;
@property (nonatomic, assign) CGFloat dotRadius;
@property (nonatomic, assign) CGFloat highlightedDotRadius;
@property (nonatomic, retain) UIImage *dotImage;
@property (nonatomic, retain) UIImage *highlightedDotImage;
@property (nonatomic, assign) NSInteger numberOfPages;
@property (nonatomic, assign) NSInteger currentPage;


- (void)setNumberOfPages:(NSInteger)numberOfPages;
- (void)setCurrentPage:(NSInteger)currentPage;

@end

@interface RScrollView : UIScrollView
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


@interface RSlideView : UIView 
<UIScrollViewDelegate,
RPageControllDataSource,
RPageControllDelegate,
UIGestureRecognizerDelegate> {
    NSInteger                   _totalPages;
    NSInteger                   _currentPage;
    
    NSInteger                   _visibleNumberOfViewsPerPage;   // Should always be a odd number
    NSInteger                   _extraPagesForLoopShow;
    
    BOOL                        _allowScrollToPage;
    
    NSMutableArray             *_reusableViews;
    
    UILongPressGestureRecognizer *_longPress;
    
    RScrollView                *_scrollView;
    RPageControll              *_pageControl;
    
    UIView                     *_highlightedView;
    NSInteger                   _selectedPageIndex;
}

@property (nonatomic, assign) IBOutlet id<RSlideViewDelegate> delegate;
@property (nonatomic, assign) IBOutlet id<RSlideViewDataSource> dataSource;

@property (nonatomic, readonly) RPageControll *pageControl;
@property (nonatomic, readonly) RScrollView *scrollView;
@property (nonatomic, readonly) NSInteger currentPage;
@property (nonatomic, assign, getter = isLoopSlide) BOOL loopSlide;
@property (nonatomic, assign, getter = isContinuousScroll) BOOL continuousScroll;
@property (nonatomic, assign, getter = isPageControlHidden) BOOL pageControlHidden;
@property (nonatomic) CGSize pageSize;  // Default to be the RSlideView's size

    // The Gap between two pages, default to be 0
@property (nonatomic) CGFloat pageMargin;

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
- (void)setPageTitleAlignment:(RPageControlTitleAlignment)align;
@end

