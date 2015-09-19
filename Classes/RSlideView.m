//
//  RSlideView.m
//  DongMan
//
//  Created by sheng tan on 12-4-4.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "RSlideView.h"

static const NSInteger kSubviewTagOffset = 100;
static const NSInteger kSubviewInvalidTagOffset = -1;

enum {
    kPageControlLabelViewTag = 123
};


@interface RScrollView : UIScrollView
@end


@interface RSlideView ()
@property (nonatomic, strong) RPageControl *pageControl;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, assign) BOOL shouldLoad;

- (void)loadNeededPages;
- (void)loadViewOfPageAtIndex:(NSInteger)index;
- (void)collectReusableViews;
- (void)clearUpandMakeReusableAtIndex:(NSInteger)index;
- (void)adjustScrollViewOffsetToSinglePage;
- (void)updateVisibalePages;
- (void)updateContentSize;

- (void)tapGestureHandler:(UITapGestureRecognizer*)tap;

- (void)didReceiveMemoryWarning:(NSNotification*)notification;
@end

@implementation RSlideView
{
    BOOL        _setFromOutside;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)commonInit
{
    self.autoresizesSubviews = YES;
    self.userInteractionEnabled = YES;
    self.clipsToBounds = YES;

    [self addSubview:self.scrollView];
    [self addSubview:self.pageControl];
    
    _pageMargin = 0.0f;
    _pageSize = self.bounds.size;

    _visibleNumberOfViewsPerPage = 1;
    _extraPagesForLoopShow = 1;
    _totalPages = 0;
    _currentPage = 0;
    _reusableViews = [[NSMutableArray alloc] initWithCapacity:16];

    _allowScrollToPage = YES;
    _pageControlHidden = YES;

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                          action:@selector(tapGestureHandler:)];
    tap.numberOfTapsRequired = 1;
    tap.numberOfTouchesRequired = 1;

    [self addGestureRecognizer:tap];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceiveMemoryWarning:)
                                                 name:UIApplicationDidReceiveMemoryWarningNotification
                                               object:nil];

}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)init
{
    return [self initWithFrame:CGRectZero];
}


#if TARGET_INTERFACE_BUILDER
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
    if (CGSizeEqualToSize(_pageSize, CGSizeZero)) {
        _pageSize = self.bounds.size;
    }
    [self updateVisibalePages];

    CGSize size = CGSizeMake(_pageSize.width + _pageMargin, _pageSize.height);

    CGRect scrollRect = CGRectMake((CGRectGetWidth(self.bounds) - _pageSize.width - _pageMargin) / 2,
                                   (CGRectGetHeight(self.bounds) - _pageSize.height) / 2,
                                   self.pageSize.width + _pageMargin, _pageSize.height);

    NSDictionary *attri = @{NSFontAttributeName: [UIFont systemFontOfSize:13],
                            NSForegroundColorAttributeName: [UIColor darkTextColor]};

    NSInteger start = self.loopSlide ? -_extraPagesForLoopShow : 0;
    for (NSInteger i = start; i <= _extraPagesForLoopShow; ++i) {
        [[UIColor grayColor] setStroke];
        [[UIColor colorWithWhite:0.9 alpha:1.0] setFill];

        CGRect rect = CGRectMake(_pageMargin / 2 + size.width * i,
                                 (size.height - _pageSize.height) / 2,
                                 _pageSize.width, _pageSize.height);
        rect = CGRectOffset(rect, scrollRect.origin.x, scrollRect.origin.y);
        UIBezierPath *path = [UIBezierPath bezierPathWithRect:rect];
        [path stroke];
        [path fill];
        NSString *page = [NSString stringWithFormat:@"Page %s%ld", self.loopSlide && i < 0 ? "N" : "", i];
        CGSize textSize = [page sizeWithAttributes:attri];
        CGPoint textPoint = CGPointMake(CGRectGetMidX(rect) - textSize.width / 2, CGRectGetMidY(rect) - textSize.height / 2);
        [page drawAtPoint:textPoint
           withAttributes:attri];
    }

    self.pageControl.numberOfPages = MIN(10, _extraPagesForLoopShow * 2 + 1);
    self.pageControl.title = @"Page 0";
}
#endif

- (CGRect)pageControlRectForBounds:(CGRect)rect
{
    return CGRectMake(0, CGRectGetHeight(rect) - 24.f, CGRectGetWidth(rect), 24.f);
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    self.scrollView.frame = CGRectMake((CGRectGetWidth(self.bounds) - _pageSize.width - _pageMargin) / 2,
                                       (CGRectGetHeight(self.bounds) - _pageSize.height) / 2,
                                       _pageSize.width + _pageMargin,
                                       _pageSize.height);
    self.pageControl.frame = [self pageControlRectForBounds:self.bounds];


    if (self.loopSlide) {
        CGFloat w = self.frame.size.width;
        self.scrollView.contentInset = UIEdgeInsetsMake(0, 2 * w, 0, 2 * w);
    }
    else {
        self.scrollView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
        [self collectReusableViews];
    }
    [self updateContentSize];
    self.scrollView.contentOffset = CGPointMake(_scrollView.frame.size.width * _currentPage, 0);
}

- (UIView*)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    if (!_pageControl.hidden && CGRectContainsPoint(_pageControl.frame, point))
        return [_pageControl hitTest:[self convertPoint:point toView:_pageControl]
                           withEvent:event];
    else if (CGRectContainsPoint(self.bounds, point))
        return [_scrollView hitTest:[self convertPoint:point toView:_scrollView]
                          withEvent:event];
    return nil;
}

#pragma mark - getter/setter

- (RPageControl*)pageControl
{
    if (!_pageControl) {
        _pageControl = [[RPageControl alloc] initWithFrame:self.bounds];
        _pageControl.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
        _pageControl.hidden = YES;
        _pageControl.dataSource = self;
        _pageControl.delegate = self;
    }
    return _pageControl;
}

- (UIScrollView *)scrollView
{
    if (!_scrollView) {
        _scrollView = [[RScrollView alloc] initWithFrame:self.bounds];
        _scrollView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        _scrollView.pagingEnabled = YES;
        _scrollView.scrollEnabled = YES;
        _scrollView.scrollsToTop = NO;
        _scrollView.clipsToBounds = NO;
        _scrollView.bounces = YES;
        _scrollView.backgroundColor = [UIColor clearColor];
        _scrollView.showsVerticalScrollIndicator = NO;
        _scrollView.showsHorizontalScrollIndicator = NO;
        _scrollView.multipleTouchEnabled = NO;
        _scrollView.autoresizesSubviews = YES;
        _scrollView.delegate = self;
        _scrollView.alwaysBounceVertical = NO;
    }
    return _scrollView;
}

- (void)setPageControlHidden:(BOOL)pageControlHidden animated:(BOOL)animated
{
    _pageControlHidden = pageControlHidden;

    self.pageControl.alpha = _pageControlHidden?1.f:0.f;
    self.pageControl.hidden = NO;
    [UIView animateWithDuration:animated ? 0.35 : 0
                     animations:^{
                         self.pageControl.alpha = _pageControlHidden ? 0.f : 1.f;
                     }
                     completion:^(BOOL finished) {
                         self.pageControl.hidden = _pageControlHidden;
                     }];
}

- (void)setPageControlHidden:(BOOL)pageControlHidden
{
    [self setPageControlHidden:pageControlHidden
                      animated:NO];
}

- (void)setPageTitleAlignment:(RPageControlTitleAlignment)align
{
    self.pageControl.titleAlignment = align;
}

- (RPageControlTitleAlignment)pageTitleAlignment
{
    return self.pageControl.titleAlignment;
}

- (void)setPageControlBackgroundColor:(UIColor *)pageControlBackgroundColor
{
    self.pageControl.backgroundColor = pageControlBackgroundColor;
}

- (UIColor *)pageControlBackgroundColor
{
    return self.pageControl.backgroundColor;
}

- (void)setDataSource:(id<RSlideViewDataSource>)dataSource
{
    _dataSource = dataSource;
    [self reloadData];
}

- (void)setContinuousScroll:(BOOL)continusScroll
{
    if (_continuousScroll == continusScroll)
        return;

    _continuousScroll = continusScroll;

    self.scrollView.pagingEnabled = !_continuousScroll;
}

- (void)setLoopSlide:(BOOL)loopSlide
{
    if (_loopSlide == loopSlide)
        return;

    _loopSlide = loopSlide;
    [self loadNeededPages];
    [self setNeedsLayout];
}

- (void)setPageSize:(CGSize)pageSize
{
    if (!(0.f < pageSize.width && pageSize.width <= self.bounds.size.width)) {
        NSLog(@"The page width should be smaller than view width");
    }

    if (!CGSizeEqualToSize(self.pageSize, pageSize)) {
        _setFromOutside = YES;
        _pageSize = pageSize;
        [self updateVisibalePages];
        [self setNeedsLayout];
    }
}

- (void)setBounds:(CGRect)bounds
{
    [super setBounds:bounds];
    if (!CGSizeEqualToSize(bounds.size, _pageSize)) {
        if (!_setFromOutside) {
            _pageSize = bounds.size;
        }
        [self updateVisibalePages];
        [self setNeedsLayout];
    }
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    if (!CGSizeEqualToSize(frame.size, _pageSize)) {
        if (!_setFromOutside) {
            _pageSize = frame.size;
        }
        [self updateVisibalePages];
        [self setNeedsLayout];
    }
}

- (void)setPageMargin:(CGFloat)pageMargin
{
    if (_pageMargin != pageMargin) {
        _pageMargin = pageMargin;
        [self updateVisibalePages];
        [self setNeedsLayout];
    }
}

#pragma mark - Private Methods

- (void)didReceiveMemoryWarning:(NSNotification *)notification
{
    @synchronized(self) {
        [_reusableViews removeAllObjects];
    }
}

- (void)loadNeededPages
{
    if (_totalPages == 0)
        return;

    for (NSInteger i = _currentPage - _extraPagesForLoopShow; i <= _currentPage + _extraPagesForLoopShow; ++i) {
        if (!self.loopSlide && !(0 <= i && i < _totalPages))
            continue;
        [self loadViewOfPageAtIndex:i];
    }
}

- (void)loadViewOfPageAtIndex:(NSInteger)index
{
    NSInteger indexToLoad = (index - index / _totalPages * _totalPages + _totalPages) % _totalPages;

    CGSize size = CGSizeMake(_pageSize.width + _pageMargin, _pageSize.height);
    UIView *view = [self viewOfPageAtIndex:index];
    BOOL shouldDisableAnimations = NO;
    if (!view) {
        shouldDisableAnimations = YES;
        view = [self.dataSource RSlideView:self
                        viewForPageAtIndex:indexToLoad];
        NSAssert(view, @"A RSlideView datasource must return a UIView!");
        view.tag = index + kSubviewTagOffset;
        view.autoresizingMask = UIViewAutoresizingNone;
        [self.scrollView addSubview:view];
    }
    BOOL animations = [UIView areAnimationsEnabled];
    [UIView setAnimationsEnabled:!shouldDisableAnimations];
    view.frame = CGRectMake(_pageMargin / 2 + size.width * index,
                            (size.height - _pageSize.height) / 2,
                            _pageSize.width, _pageSize.height);
    [UIView setAnimationsEnabled:animations];
}

- (void)collectReusableViews
{
    NSInteger range = (_visibleNumberOfViewsPerPage + 1) / 2 + 1;
    if (self.loopSlide) {
        for (NSInteger i = -_extraPagesForLoopShow; i <= _currentPage-range; i++) {
            [self clearUpandMakeReusableAtIndex:i];
        }
        for (NSInteger i = _currentPage+range; i <= _totalPages - 1 + _extraPagesForLoopShow; i++) {
            [self clearUpandMakeReusableAtIndex:i];
        }
    }
    else {
        for (NSInteger i = -_extraPagesForLoopShow; i < MAX(0, _currentPage - _extraPagesForLoopShow); i++) {
            [self clearUpandMakeReusableAtIndex:i];
        }
        for (NSInteger i = MIN(_totalPages-1, _currentPage+_extraPagesForLoopShow) + 1; i <= _totalPages - 1 + _extraPagesForLoopShow; i++) {
            [self clearUpandMakeReusableAtIndex:i];
        }
    }
}

- (void)clearUpandMakeReusableAtIndex:(NSInteger)index
{
    UIView *view = [self viewOfPageAtIndex:index];
    if (view) {
        view.tag = kSubviewInvalidTagOffset;
        if (![_reusableViews containsObject:view])
            [_reusableViews addObject:view];
        [view removeFromSuperview];
    }
}

- (void)updateVisibalePages
{
    if (CGSizeEqualToSize(_pageSize, CGSizeZero))
        return;

    CGFloat w = 2 * (_pageSize.width + _pageMargin);
    NSInteger visiblePages = floorf((CGRectGetWidth(self.bounds) - _pageSize.width - _pageMargin) / w) * 2 + 1;
    NSInteger extraPageToLoad = ceilf(CGRectGetWidth(self.bounds) / w);

    if (visiblePages != _visibleNumberOfViewsPerPage || extraPageToLoad != _extraPagesForLoopShow) {
        [self collectReusableViews];
        _visibleNumberOfViewsPerPage = visiblePages;
        _extraPagesForLoopShow = extraPageToLoad;
    }
    [self loadNeededPages];
}

- (void)updateContentSize
{
    self.scrollView.contentSize = CGSizeMake(CGRectGetWidth(_scrollView.frame) * _totalPages,
                                             _scrollView.bounds.size.height);
}

- (void)adjustScrollViewOffsetToSinglePage
{
    //CGFloat width = self.scrollView.frame.size.width;
    if (self.scrollView.isDecelerating)
        return;

    self.pageControl.currentPage = _currentPage;
    [self.scrollView setContentOffset:CGPointMake(_currentPage*_scrollView.frame.size.width, 0)
                             animated:YES];
}

- (void)tapGestureHandler:(UITapGestureRecognizer *)tap
{
    switch (tap.state) {
        case UIGestureRecognizerStateBegan:

            break;
        case UIGestureRecognizerStateChanged:
            break;
        case UIGestureRecognizerStateEnded:
        {
            CGPoint location = [tap locationInView:_scrollView];
            UIView *view = [_scrollView hitTest:location withEvent:nil];
            NSInteger idx = [self indexOfPageView:view];
            if (idx != NSNotFound) {
                if ([self.delegate respondsToSelector:@selector(RSlideView:tapOnPageAtIndex:)]) {
                    [self.delegate RSlideView:self tapOnPageAtIndex:(idx+_totalPages)%_totalPages];
                }
            }
        }
            break;
        default:
            break;
    }
}

#pragma mark - Public Methods

- (void)reloadData
{
    if (![self.dataSource respondsToSelector:@selector(RSlideViewNumberOfPages)])
        return;

    [_reusableViews addObjectsFromArray:self.scrollView.subviews];
    [self.scrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];

    _totalPages = [self.dataSource RSlideViewNumberOfPages];
    _currentPage = MAX(MIN(_totalPages - 1, _currentPage), 0);

    self.pageControl.numberOfPages = _totalPages;
    self.pageControl.currentPage = _currentPage;

    [self loadNeededPages];
    [self setNeedsLayout];
}

- (UIView*)dequeueReusableView
{
    UIView *reuse = nil;
    @synchronized(self) {
        reuse = [_reusableViews lastObject];
        if (reuse)
            [_reusableViews removeLastObject];
    }

    return reuse;
}

- (UIView*)viewOfPageAtIndex:(NSInteger)index
{
    return [self.scrollView viewWithTag:(index + kSubviewTagOffset)];
}

- (NSInteger)indexOfPageView:(UIView *)view
{
    if ([_scrollView.subviews containsObject:view]) {
        return view.tag - kSubviewTagOffset;
    }
    return NSNotFound;
}

- (void)previousPage
{
    if (!self.loopSlide && _currentPage == 0)
        return;
    [self scrollToPageAtIndex:_currentPage - 1];
}

- (void)nextPage
{
    if (!self.loopSlide && _currentPage == _totalPages - 1)
        return;
    [self scrollToPageAtIndex:_currentPage + 1];
}

- (void)scrollToPageAtIndex:(NSInteger)index
{
    if (index == _currentPage)
        return;
    if (_allowScrollToPage) {
        _allowScrollToPage = NO;
        //index = (index - index / _totalPages * _totalPages + _totalPages) % _totalPages;
        self.shouldLoad = YES;
        [self.scrollView setContentOffset:CGPointMake(_scrollView.frame.size.width*index, 0)
                                 animated:YES];
    }
}

- (void)scrollToPageOffset:(CGFloat)pageOffset
{
    self.shouldLoad = YES;
    CGPoint offset = CGPointMake(pageOffset*_scrollView.frame.size.width, 0);
    self.scrollView.contentOffset = offset;
}

#pragma mark - RPageControl DataSource

- (NSString*)pageControlTitleForPage:(NSInteger)index
{
    if ([self.dataSource respondsToSelector:@selector(RSlideView:titleForPageAtIndex:)])
        return [self.dataSource RSlideView:self titleForPageAtIndex:index];
    return nil;
}

#pragma mark - RPageControl Delegate

- (void)pageControlDidChangePage:(RPageControl *)pageControl
{
    NSInteger page = self.pageControl.currentPage;

    CGPoint offset = CGPointMake(_scrollView.frame.size.width*page, 0);

    [self.scrollView setContentOffset:offset
                             animated:YES];
}

#pragma mark - UIScrollView Delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (!self.shouldLoad && !scrollView.isDragging && !scrollView.isDecelerating)
        return;
    
    CGFloat halfWidth = _scrollView.frame.size.width / 2.f;
    CGFloat offset = scrollView.contentOffset.x;

    if ([self.delegate respondsToSelector:@selector(RSlideView:didScrollAtPageOffset:)]) {
        [self.delegate RSlideView:self
            didScrollAtPageOffset:offset / _scrollView.frame.size.width];
    }

    NSInteger displayingPage = floorf((offset + halfWidth) / _scrollView.frame.size.width);

    if (displayingPage != _currentPage) {   // have to load new page
        if (!self.loopSlide) {
            if (displayingPage < 0 || displayingPage >= _totalPages)
                return;
        }
        _currentPage = displayingPage;

        CGPoint offset = self.scrollView.contentOffset;
        if (_currentPage < 0) {
            _currentPage = _totalPages - 1;
            offset.x += _scrollView.frame.size.width * _totalPages;
        }
        else if (_currentPage >= _totalPages) {
            _currentPage = 0;
            offset.x -= _scrollView.frame.size.width * _totalPages;
        }
        self.scrollView.delegate = nil;
        self.scrollView.contentOffset = offset;
        self.scrollView.delegate = self;
        [self collectReusableViews];
        [self loadNeededPages];
    }
    self.pageControl.currentPage = _currentPage;
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView
                  willDecelerate:(BOOL)decelerate
{
    if (!self.scrollView.pagingEnabled) {
        if (!decelerate) {
            [self adjustScrollViewOffsetToSinglePage];
        }
    }
    if (!decelerate) {
        self.shouldLoad = NO;
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    if (!self.scrollView.pagingEnabled) {
        if (self.continuousScroll) {
            [self adjustScrollViewOffsetToSinglePage];
        }
    }
    if ([self.delegate respondsToSelector:@selector(RSlideViewDidEndScrollAnimation:)])
        [self.delegate RSlideViewDidEndScrollAnimation:self];

    self.shouldLoad = NO;
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    CGFloat halfWidth = _scrollView.frame.size.width / 2.f;

    _currentPage = floorf((scrollView.contentOffset.x + halfWidth) / _scrollView.frame.size.width);
    //[self adjustScrollViewOffsetToSinglePage];
    self.pageControl.currentPage = _currentPage;

    _allowScrollToPage = YES;

    if ([self.delegate respondsToSelector:@selector(RSlideViewDidEndScrollAnimation:)])
        [self.delegate RSlideViewDidEndScrollAnimation:self];

    self.shouldLoad = NO;
}

#pragma mark - UIGesture Delegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
       shouldReceiveTouch:(UITouch *)touch
{
    return NO;
}

@end


#define PAGE_CONTROL_PADDING 8.0f

@implementation RPageControl

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.autoresizesSubviews = YES;
        self.clipsToBounds = YES;
        self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.6f];

        _pageControl = [[UIPageControl alloc] initWithFrame:self.bounds];
        _pageControl.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _pageControl.hidesForSinglePage = YES;
        _pageControl.defersCurrentPageDisplay = YES;
        _pageControl.userInteractionEnabled = YES;
        _pageControl.contentVerticalAlignment = UIControlContentVerticalAlignmentBottom;
        _pageControl.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;

        [_pageControl addTarget:self
                         action:@selector(onPageChanged:)
               forControlEvents:UIControlEventValueChanged];

        [self addSubview:_pageControl];

    }
    return self;
}

- (UIView*)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    if (CGRectContainsPoint(self.bounds, point))
        return _pageControl;
    return nil;
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    [_pageControl sizeToFit];

    CGRect frame = self.bounds;
    frame.size.width = [_pageControl sizeForNumberOfPages:_pageControl.numberOfPages].width;

    CGRect titleFrame = self.bounds;
    titleFrame.size.width = CGRectGetWidth(self.bounds) - CGRectGetWidth(frame) - PAGE_CONTROL_PADDING * 2;
    switch (_titleAlignment) {
        case RPageControllTitleAlignLeft:
            titleFrame.origin.x = PAGE_CONTROL_PADDING;
            frame.origin.x = self.bounds.size.width - frame.size.width - PAGE_CONTROL_PADDING;
            break;
        case RPageControllTitleAlignRight:
            titleFrame.origin.x = CGRectGetWidth(_pageControl.frame) + PAGE_CONTROL_PADDING;
            frame.origin.x = PAGE_CONTROL_PADDING;
        default:
            break;
    }
    _titleLabel.frame = titleFrame;
    _pageControl.frame = frame;
}

- (void)onPageChanged:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(pageControlDidChangePage:)]) {
        [self.delegate pageControlDidChangePage:self];
    }
}

- (void)setTitle:(NSString *)title
{
    if (title && ![title isEqualToString:@""]) {
        if (!_titleLabel) {

            UILabel *label = [[UILabel alloc] initWithFrame:self.bounds];
            label.font = [UIFont systemFontOfSize:12];
            label.numberOfLines = 1;
            label.adjustsFontSizeToFitWidth = YES;
#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_6_0
            label.minimumFontSize = 10;
#else
            label.minimumScaleFactor = 10;
#endif
            label.textColor = [UIColor whiteColor];
            label.backgroundColor = [UIColor clearColor];
#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_6_0
            label.lineBreakMode = UILineBreakModeMiddleTruncation;
#else
            label.lineBreakMode = NSLineBreakByTruncatingMiddle;
#endif
            label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            [self addSubview:label];
            _titleLabel = label;

            self.titleAlignment = self.titleAlignment;
        }
    }

    _titleLabel.text = title;
}

- (void)setCurrentPage:(NSInteger)currentPage
{
    [_pageControl setCurrentPage:currentPage];
    if ([self.dataSource respondsToSelector:@selector(pageControlTitleForPage:)]) {
        self.title = [self.dataSource pageControlTitleForPage:currentPage];
    }
}

- (NSInteger)currentPage
{
    return _pageControl.currentPage;
}

- (void)setNumberOfPages:(NSInteger)numberOfPages
{
    _pageControl.numberOfPages = numberOfPages;
    [self setNeedsLayout];
}

- (NSInteger)numberOfPages
{
    return _pageControl.numberOfPages;
}

- (void)setTitleAlignment:(RPageControlTitleAlignment)titleAlignment
{
    _titleAlignment = titleAlignment;
    switch (self.titleAlignment) {
        case RPageControllTitleAlignLeft:
#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_6_0
            _titleLabel.textAlignment = UITextAlignmentLeft;
#else
            _titleLabel.textAlignment = NSTextAlignmentLeft;
#endif
            break;
        case RPageControllTitleAlignRight:
#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_6_0
            _titleLabel.textAlignment = UITextAlignmentRight;
#else
            _titleLabel.textAlignment = NSTextAlignmentRight;
#endif

            break;
        default:
            break;
    }
    [self setNeedsLayout];
}

@end


@implementation RScrollView

- (UIView*)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    for (UIView *view in self.subviews) {
        if (CGRectContainsPoint(view.frame, point)) {
            return [view hitTest:[self convertPoint:point
                                             toView:view]
                       withEvent:event] ?: view;
        }
    }
    return self;
}

@end
