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

- (NSString*)RPageControllTitleForPage:(NSInteger)index;

@end


@interface RSlideView : UIView 
<UIScrollViewDelegate,RPageControllDataSource> {
    NSInteger                   _totalPages;
    NSInteger                   _currentPage;
    
    CGFloat                     _scrollWidth;
    CGFloat                     _centralizeOffset;
    CGFloat                     _loopOffset;
    NSInteger                   _visibleNumberOfViewsPerPage;   // Should always be a odd number
    NSInteger                   _extraPagesForLoopShow;
    
    BOOL                        _allowScrollToPage;
    
    NSMutableArray             *_reusableViews;
    
    UIView                     *_firstView;
    UIView                     *_lastView;
    
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
- (void)scrollToPageAtIndex:(NSInteger)index;

- (void)previousPage;
- (void)nextPage;

- (void)setPageControlHidden:(BOOL)pageControlHidden 
                    animated:(BOOL)animated;
@end

typedef enum {
    RPageControllTitleAlignLeft = 0,
    RPageControllTitleAlignRight
}RPageControlTitleAlignment;

@interface RPageControll : UIPageControl {
@private
    UILabel                     *_titleLabel;
}
@property (nonatomic, assign) NSString *title;
@property (nonatomic, assign) id<RPageControllDataSource> dataSource;
@property (nonatomic, assign) RPageControlTitleAlignment titleAlignment;
@property (nonatomic, assign) CGFloat dotMargin;
@property (nonatomic, assign) CGFloat dotRadius;
@property (nonatomic, assign) CGFloat highlightedDotRadius;
@property (nonatomic, retain) UIImage *dotImage;
@property (nonatomic, retain) UIImage *highlightedDotImage;
@end
