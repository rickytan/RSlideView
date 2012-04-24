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

@protocol RSlideViewDelegate <NSObject>
@optional
- (void)RSlideView:(RSlideView*)slideView tapStartOnPageAtIndex:(NSInteger)index;
- (void)RSlideView:(RSlideView*)slideView tapEndOnPageAtIndex:(NSInteger)index;
- (void)RSlideView:(RSlideView *)slideView doubleTapOnPageAtIndex:(NSInteger)index;

- (void)RSlideView:(RSlideView*)sliderView didScrollAtPageOffset:(CGFloat)pageOffset;
@end

@protocol RSlideViewDataSource <NSObject>
@required
- (NSInteger)RSlideViewNumberOfPages;
- (UIView*)RSlideView:(RSlideView*)slideView 
    viewForPageAtIndex:(NSInteger)index;
@optional
- (NSString*)RSlideView:(RSlideView*)slideView titleForPageAtIndex:(NSInteger)index;
@end


@protocol RPageControllDataSource <NSObject>
@optional
- (NSString*)RPageControllTitleForPage:(NSInteger)index;

@end

@protocol RPageControllDelegate <NSObject>
@optional
- (void)RPageControllDidChangePage:(RPageControll*)pageControl;

@end


@interface RSlideView : UIControl 
<UIScrollViewDelegate,
RPageControllDataSource,
RPageControllDelegate,
UIGestureRecognizerDelegate> {
    NSInteger                   _totalPages;
    NSInteger                   _currentPage;
    
    CGFloat                     _scrollWidth;
    CGFloat                     _centralizeOffset;
    CGFloat                     _loopOffset;
    NSInteger                   _visibleNumberOfViewsPerPage;   // Should always be a odd number
    NSInteger                   _extraPagesForLoopShow;
    
    BOOL                        _allowScrollToPage;
    
    NSMutableArray             *_reusableViews;
    
    UILongPressGestureRecognizer *_longPress;
    
    UIScrollView               *_scrollView;
    RPageControll              *_pageControl;
}

@property (nonatomic, assign) id<RSlideViewDelegate> delegate;
@property (nonatomic, assign) id<RSlideViewDataSource> dataSource;

@property (nonatomic, readonly) RPageControll *pageControl;
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
- (void)scrollToPageAtIndex:(NSInteger)index;   // Scroll to a page, e.g 1 ... n
- (void)scrollToPageOffset:(CGFloat)pageOffset; // Scroll to a offset, can be 1.25

- (void)previousPage;
- (void)nextPage;

- (void)setPageControlHidden:(BOOL)pageControlHidden 
                    animated:(BOOL)animated;
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
