    //
    //  RSlideView.m
    //  DongMan
    //
    //  Created by sheng tan on 12-4-4.
    //  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
    //

#import "RSlideView.h"
#import "RSlideView+PrivateMethods.h"

static const NSInteger kSubviewTagOffset = 100;
static const NSInteger kSubviewInvalidTagOffset = -1;

enum {
    kPageControlLabelViewTag = 123
};

@implementation RSlideView
@synthesize pageControl = _pageControl;
@synthesize scrollView = _scrollView;
@synthesize delegate = _delegate;
@synthesize dataSource = _dataSource;
@synthesize loopSlide = _loopSlide,continuousScroll = _continuousScroll,pageControlHidden = _pageControlHidden;
@synthesize pageSize = _pageSize;
@synthesize pageMargin = _pageMargin;

- (void)dealloc
{
    [_pageControl release];
    [_scrollView release];
    
    [_reusableViews release];
    [super dealloc];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
            // Initialization code
        self.autoresizesSubviews = YES;
        self.userInteractionEnabled = YES;
        
        [self addSubview:self.scrollView];
        
        CGRect rect = self.pageControl.frame;
        rect.origin = CGPointMake(0, rect.size.height - 24.f);
        rect.size = CGSizeMake(rect.size.width, 24.f);
        self.pageControl.frame = rect;
        [self addSubview:self.pageControl];
        
        _reusableViews = [[NSMutableArray alloc] initWithCapacity:16];
        _visibleNumberOfViewsPerPage = 1;
        _totalPages = 0;
        _currentPage = 0;
        
        _allowScrollToPage = YES;
        
        self.pageMargin = 0.f;
        self.pageSize = frame.size;
        
        
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressGestureHandler:)];
        longPress.numberOfTouchesRequired = 1;
        longPress.minimumPressDuration = 0.1;
        longPress.delaysTouchesBegan = NO;
        longPress.delegate = self;
        [self addGestureRecognizer:longPress];
        [longPress release];
        
        _longPress = longPress;
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                              action:@selector(tapGestureHandler:)];
        tap.numberOfTapsRequired = 1;
        tap.numberOfTouchesRequired = 1;
        [self addGestureRecognizer:tap];
        [tap release];
        /*
         [self addTarget:self
         action:@selector(onTapdown:)
         forControlEvents:UIControlEventAllTouchEvents];
         [self addTarget:self
         action:@selector(onTapupinside:)
         forControlEvents:UIControlEventTouchUpInside];
         */
        
            //[self.scrollView.panGestureRecognizer requireGestureRecognizerToFail:longPress];
        [self.scrollView.panGestureRecognizer addTarget:self
                                                 action:@selector(panGestureHandler:)];
        
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(didReceiveMemoryWarning:)
                                                     name:UIApplicationDidReceiveMemoryWarningNotification
                                                   object:nil];
    }
    return self;
}

- (id)init
{
    return [self initWithFrame:CGRectZero];
}

/*
 // Only override drawRect: if you perform custom drawing.
 // An empty implementation adversely affects performance during animation.
 - (void)drawRect:(CGRect)rect
 {
 // Drawing code
 }
 */

#pragma mark - getter/setter

- (RPageControll*)pageControl
{
    if (!_pageControl) {
        _pageControl = [[RPageControll alloc] initWithFrame:self.bounds];
        _pageControl.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
        _pageControl.hidden = YES;
        _pageControl.dataSource = self;
        _pageControl.delegate = self;
    }
    return _pageControl;
}

- (UIScrollView*)scrollView
{
    if (!_scrollView) {
        _scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
        _scrollView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        _scrollView.pagingEnabled = YES;
        _scrollView.scrollEnabled = YES;
        _scrollView.bounces = YES;
        _scrollView.backgroundColor = [UIColor clearColor];
        _scrollView.showsVerticalScrollIndicator = NO;
        _scrollView.showsHorizontalScrollIndicator = NO;
        _scrollView.multipleTouchEnabled = NO;
        _scrollView.autoresizesSubviews = YES;
        _scrollView.delegate = self;
    }
    return _scrollView;
}

- (void)setPageControlHidden:(BOOL)pageControlHidden animated:(BOOL)animated
{
    _pageControlHidden = pageControlHidden;
    
    self.pageControl.alpha = _pageControlHidden?1.f:0.f;
    self.pageControl.hidden = NO;
    [UIView animateWithDuration:animated?0.35:0
                     animations:^{
                         self.pageControl.alpha = _pageControlHidden?0.f:1.f;
                     }
                     completion:^(BOOL finished) {
                         self.pageControl.hidden = _pageControlHidden;
                     }];
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
    if (_continuousScroll) {
        self.scrollView.pagingEnabled = NO;
        [self.scrollView.panGestureRecognizer removeTarget:self 
                                                    action:@selector(panGestureHandler:)];
    }
    else {
        self.scrollView.pagingEnabled = (_scrollWidth == CGRectGetWidth(_scrollView.frame));
        [self.scrollView.panGestureRecognizer addTarget:self
                                                 action:@selector(panGestureHandler:)];
    }
        //self.scrollView.pagingEnabled = !_continuousScroll;
}

- (void)setLoopSlide:(BOOL)loopSlide
{
    if (_loopSlide == loopSlide)
        return;
    
    _loopSlide = loopSlide;
    
    if (_loopSlide) {
        _loopOffset = self.scrollView.frame.size.width;
        
        self.scrollView.contentOffset = CGPointMake(self.scrollView.contentOffset.x+_loopOffset, 0);
    }
    else {
        CGFloat f = _loopOffset;
        _loopOffset = 0;
        self.scrollView.contentOffset = CGPointMake(self.scrollView.contentOffset.x-f, 0);
        [self collectReusableViews];
    }
    [self updateContentSize];
    [self loadNeededPages];
}

- (void)setPageSize:(CGSize)pageSize
{
    NSAssert(pageSize.width <= self.bounds.size.width, @"The page width should be smaller than view width");
    if (pageSize.width == self.scrollView.bounds.size.width) {
        self.scrollView.pagingEnabled = YES;
    }
    else {
        self.scrollView.pagingEnabled = NO;
    }
    if (!CGSizeEqualToSize(_pageSize, pageSize)) {
        _pageSize = pageSize;
        [self updateVisibalePages];
    }
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    if (!CGSizeEqualToSize(frame.size, _pageSize))
        [self updateVisibalePages];
}

- (void)setPageMargin:(CGFloat)pageMargin
{
    if (_pageMargin != pageMargin) {
        _pageMargin = pageMargin;
        [self updateVisibalePages];
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
    for (NSInteger i = _currentPage-_extraPagesForLoopShow; i <= _currentPage+_extraPagesForLoopShow; ++i) {
        if (!self.loopSlide && !(0 <= i && i < _totalPages))
            continue;
        [self loadViewOfPageAtIndex:i];
    }
}

- (void)loadViewOfPageAtIndex:(NSInteger)index
{
    NSInteger indexToLoad = index;
    if (indexToLoad < 0)
        indexToLoad += _totalPages;
    else if (indexToLoad > _totalPages - 1)
        indexToLoad -= _totalPages;
    
    CGSize size = self.scrollView.bounds.size;
    UIView *view = [self viewOfPageAtIndex:index];
    if (!view) {
        view = [self.dataSource RSlideView:self
                        viewForPageAtIndex:indexToLoad];
        view.tag = index + kSubviewTagOffset;
        view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.scrollView addSubview:view];
    }
    view.frame = CGRectMake(_centralizeOffset + _pageMargin + _scrollWidth * index + _loopOffset,
                            (size.height - _pageSize.height) / 2,
                            _pageSize.width, _pageSize.height);
}

- (void)collectReusableViews
{
    NSInteger range = (_visibleNumberOfViewsPerPage + 1) / 2 + 1;
    if (self.loopSlide) {
        for (int i=-_extraPagesForLoopShow; i<=_currentPage-range; i++) {
            [self clearUpandMakeReusableAtIndex:i];
        }
        for (int i=_currentPage+range; i<=_totalPages-1+_extraPagesForLoopShow; i++) {
            [self clearUpandMakeReusableAtIndex:i];
        }
    }
    else {
        for (int i=-_extraPagesForLoopShow; i<MAX(0, _currentPage - _extraPagesForLoopShow); i++) {
            [self clearUpandMakeReusableAtIndex:i];
        }
        for (int i=MIN(_totalPages-1, _currentPage+_extraPagesForLoopShow)+1; i<=_totalPages-1+_extraPagesForLoopShow; i++) {
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

- (void)updateScrollViewOffset
{
    
}

- (void)updateVisibalePages
{
    if (CGSizeEqualToSize(_pageSize, CGSizeZero))
        return;
    
    _visibleNumberOfViewsPerPage = floorf((self.scrollView.bounds.size.width - _pageSize.width - _pageMargin) / (2 * (_pageSize.width + _pageMargin))) * 2 + 1;
    _extraPagesForLoopShow = ceilf(self.scrollView.bounds.size.width / (2*(_pageMargin + _pageSize.width)));
    _scrollWidth = _pageMargin + _pageSize.width;
    _centralizeOffset = (self.scrollView.bounds.size.width - _pageSize.width) / 2 - _pageMargin;
    
    [self reloadData];
}

- (void)updateContentSize
{
    self.scrollView.contentSize = CGSizeMake(_scrollWidth*_totalPages+_pageMargin+_centralizeOffset*2+_loopOffset*2,
                                             self.scrollView.bounds.size.height);
}

- (void)adjustScrollViewOffsetToSinglePage
{
        //CGFloat width = self.scrollView.frame.size.width;
    if (self.scrollView.isDecelerating)
        return;
    
    self.pageControl.currentPage = _currentPage;
    [self.scrollView setContentOffset:CGPointMake(_currentPage*_scrollWidth+_loopOffset, 0) 
                             animated:YES];
}


- (void)onTapdown:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(RSlideView:tapStartOnPageAtIndex:)]) {
        [self.delegate RSlideView:self tapStartOnPageAtIndex:_currentPage];
    }
}

- (void)onTapupinside:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(RSlideView:tapEndOnPageAtIndex:)]) {
        [self.delegate RSlideView:self tapEndOnPageAtIndex:_currentPage];
    }
}

- (void)longPressGestureHandler:(UILongPressGestureRecognizer *)longPress
{
    switch (longPress.state) {
        case UIGestureRecognizerStateBegan:
            if ([self.delegate respondsToSelector:@selector(RSlideView:tapStartOnPageAtIndex:)]) {
                [self.delegate RSlideView:self tapStartOnPageAtIndex:_currentPage];
            }
            break;
        case UIGestureRecognizerStateChanged:
            break;
        case UIGestureRecognizerStateEnded:
            if ([self.delegate respondsToSelector:@selector(RSlideView:tapEndOnPageAtIndex:)]) {
                [self.delegate RSlideView:self tapEndOnPageAtIndex:_currentPage];
            }
            [self adjustScrollViewOffsetToSinglePage];
            break;
        default:
            break;
    }
}

- (void)tapGestureHandler:(UITapGestureRecognizer *)tap
{
    switch (tap.state) {
        case UIGestureRecognizerStateBegan:
            if ([self.delegate respondsToSelector:@selector(RSlideView:tapStartOnPageAtIndex:)]) {
                [self.delegate RSlideView:self tapStartOnPageAtIndex:_currentPage];
            }
            break;
        case UIGestureRecognizerStateChanged:
            break;
        case UIGestureRecognizerStateEnded:
            if ([self.delegate respondsToSelector:@selector(RSlideView:tapEndOnPageAtIndex:)]) {
                [self.delegate RSlideView:self tapEndOnPageAtIndex:_currentPage];
            }
            [self adjustScrollViewOffsetToSinglePage];
            break;
        default:
            break;
    }
}

- (void)panGestureHandler:(UIPanGestureRecognizer *)pan
{
    switch (pan.state) {
        case UIGestureRecognizerStateBegan:
            ;
            break;
        case UIGestureRecognizerStateChanged:
            ;
            break;
        case UIGestureRecognizerStateEnded:
        {
            if (!self.scrollView.pagingEnabled) {
                CGPoint v = [pan velocityInView:self];
                if (v.x < -360) {
                    [self nextPage];
                }
                else if (v.x > 360) {
                    [self previousPage];
                }
                else {
                    [self adjustScrollViewOffsetToSinglePage];
                }
            }
            break;
        }
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
    _currentPage = MAX(MIN(_totalPages - 1, _currentPage),0);
    
    self.pageControl.numberOfPages = _totalPages;
    self.pageControl.currentPage = _currentPage;
    
    [self updateContentSize];
    
    self.scrollView.contentOffset = CGPointMake(_scrollWidth * _currentPage+_loopOffset, 0);
    
    [self loadNeededPages];
}

- (UIView*)dequeueReusableView
{
    UIView *reuse = nil;
    @synchronized(self) {
        @try {
            reuse = [[_reusableViews lastObject] retain];
            [_reusableViews removeLastObject];
        }
        @catch (NSException *exception) {
                //
        }
    }
    
    return [reuse autorelease];
}

- (UIView*)viewOfPageAtIndex:(NSInteger)index
{
    return [self.scrollView viewWithTag:(index + kSubviewTagOffset)];
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
    if (_allowScrollToPage) {
        _allowScrollToPage = NO;
        [self.scrollView setContentOffset:CGPointMake(_scrollWidth*index+_loopOffset, 0)
                                 animated:YES];
    }
}

- (void)scrollToPageOffset:(CGFloat)pageOffset
{
    CGPoint offset = CGPointMake(pageOffset*_scrollWidth+_loopOffset, 0);
    self.scrollView.contentOffset = offset;
}

#pragma mark - RPageControl DataSource

- (NSString*)RPageControllTitleForPage:(NSInteger)index
{
    if ([self.dataSource respondsToSelector:@selector(RSlideView:titleForPageAtIndex:)])
        return [self.dataSource RSlideView:self titleForPageAtIndex:index];
    return nil;
}

#pragma mark - RPageControl Delegate

- (void)RPageControllDidChangePage:(RPageControll *)pageControl
{
    NSInteger page = self.pageControl.currentPage;
    
    CGPoint offset = CGPointMake(_scrollWidth*page+_loopOffset, 0);
    
    [self.scrollView setContentOffset:offset
                             animated:YES];
}

#pragma mark - UIScrollView Delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat halfWidth = _scrollWidth / 2.f;
    CGFloat offset = scrollView.contentOffset.x - _loopOffset;
    
    if ([self.delegate respondsToSelector:@selector(RSlideView:didScrollAtPageOffset:)]) {
        [self.delegate RSlideView:self
            didScrollAtPageOffset:offset / _scrollWidth];
    }
    
    NSInteger displayingPage = floorf((offset + halfWidth) / _scrollWidth);
    
    if (displayingPage != _currentPage) {   // have to load new page
        if (!self.loopSlide) {
            if (displayingPage < 0 || displayingPage >= _totalPages)
                return;
        }
        _currentPage = displayingPage;
        
        CGPoint offset = self.scrollView.contentOffset;
        if (_currentPage <= -1) {
            _currentPage = _totalPages - 1;
            offset.x += _scrollWidth * _totalPages;
        }
        else if (_currentPage >= _totalPages) {
            _currentPage = 0;
            offset.x += - _scrollWidth * _totalPages;
        }
            //self.scrollView.delegate = nil;
        self.scrollView.contentOffset = offset;
            //self.scrollView.delegate = self;
        [self collectReusableViews]; 
        [self loadNeededPages];
    }
    self.pageControl.currentPage = _currentPage;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView
{
    
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView 
                  willDecelerate:(BOOL)decelerate
{
    if (!self.scrollView.pagingEnabled) {
        if (!decelerate) {
            [self adjustScrollViewOffsetToSinglePage];
        }
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    if (!self.scrollView.pagingEnabled) {
        if (self.continuousScroll) {
            [self adjustScrollViewOffsetToSinglePage];
        }
    }
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    CGFloat halfWidth = _scrollWidth / 2.f;
    
    _currentPage = floorf((scrollView.contentOffset.x - _loopOffset + halfWidth) / _scrollWidth);
        //[self adjustScrollViewOffsetToSinglePage];
    self.pageControl.currentPage = _currentPage;
    
    _allowScrollToPage = YES;
}

#pragma mark - UIGesture Delegate


@end


@implementation RPageControll
@synthesize title = _title;
@synthesize dataSource = _dataSource;
@synthesize delegate = _delegate;
@synthesize titleAlignment;
@synthesize dotImage = _dotImage, highlightedDotImage = _highlightedDotImage;
@synthesize dotMargin, dotRadius, highlightedDotRadius;
@synthesize numberOfPages = _numberOfPages, currentPage = _currentPage;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.autoresizesSubviews = YES;
        self.clipsToBounds = YES;
        
        _pageControl = [[UIPageControl alloc] initWithFrame:self.bounds];
        _pageControl.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _pageControl.hidesForSinglePage = YES;
        _pageControl.defersCurrentPageDisplay = YES;
        _pageControl.contentVerticalAlignment = UIControlContentVerticalAlignmentBottom;
        _pageControl.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        [_pageControl addTarget:self
                         action:@selector(onPageChanged:)
               forControlEvents:UIControlEventValueChanged];
        
        [self addSubview:_pageControl];
        [_pageControl release];
    }
    return self;
}

- (void)onPageChanged:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(RPageControllDidChangePage:)]) {
        [self.delegate RPageControllDidChangePage:self];
    }
}

- (void)setTitle:(NSString *)title
{
    if (![title isEqualToString:@""]) {
        
        if (!_titleLabel) {
            self.backgroundColor = [UIColor colorWithRed:0.f
                                                   green:0.f
                                                    blue:0.f
                                                   alpha:0.6f];
            
            UILabel *label = [[UILabel alloc] initWithFrame:self.bounds];
            label.font = [UIFont systemFontOfSize:12];
            label.numberOfLines = 1;
            label.adjustsFontSizeToFitWidth = YES;
            label.minimumFontSize = 10;
            label.textColor = [UIColor whiteColor];
            label.backgroundColor = [UIColor clearColor];
            label.lineBreakMode = UILineBreakModeMiddleTruncation;
            label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
            [self addSubview:label];
            _titleLabel = label;
            [label release];
            
            self.titleAlignment = self.titleAlignment;
        }
    }
    else {
        self.backgroundColor = [UIColor clearColor];
    }
    
    _titleLabel.text = title;
}

- (void)setCurrentPage:(NSInteger)currentPage
{
    [_pageControl setCurrentPage:currentPage];
    if ([self.dataSource respondsToSelector:@selector(RPageControllTitleForPage:)]) {
        self.title = [self.dataSource RPageControllTitleForPage:currentPage];
    }
}

- (NSInteger)currentPage
{
    return _pageControl.currentPage;
}

- (void)setNumberOfPages:(NSInteger)numberOfPages
{
    _pageControl.numberOfPages = numberOfPages;
    CGRect frame = _pageControl.frame;
    frame.size.width = numberOfPages * 16 + 8;
    switch (titleAlignment) {
        case RPageControllTitleAlignLeft:
            frame.origin.x = self.bounds.size.width - frame.size.width;
            break;
        case RPageControllTitleAlignRight:
            frame.origin.x = 0;
        default:
            break;
    }
    _pageControl.frame = frame;
}

- (NSInteger)numberOfPages
{
    return _pageControl.numberOfPages;
}

- (void)setTitleAlignment:(RPageControlTitleAlignment)_titleAlignment
{
    titleAlignment = _titleAlignment;
    CGRect frame = self.bounds;
    frame.size.width = CGRectGetWidth(frame) - CGRectGetWidth(_pageControl.frame);
    switch (titleAlignment) {
        case RPageControllTitleAlignLeft:
            _titleLabel.frame = frame;
            _titleLabel.textAlignment = UITextAlignmentLeft;
            break;
        case RPageControllTitleAlignRight:
            frame.origin.x = CGRectGetWidth(_pageControl.frame);
            _titleLabel.frame = frame;
            _titleLabel.textAlignment = UITextAlignmentRight;
            break;
        default:
            break;
    }
}

@end
