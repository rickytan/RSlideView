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
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (void)commonInit
{
    self.autoresizesSubviews = YES;
    self.userInteractionEnabled = YES;
    self.clipsToBounds = YES;
    
    [self addSubview:self.scrollView];
    
    CGRect rect = self.pageControl.frame;
    rect.origin = CGPointMake(0, rect.size.height - 24.f);
    rect.size = CGSizeMake(rect.size.width, 24.f);
    self.pageControl.frame = rect;
    [self addSubview:self.pageControl];
    
    _reusableViews = [[NSMutableArray alloc] initWithCapacity:16];
    _visibleNumberOfViewsPerPage = 1;
    _extraPagesForLoopShow = 1;
    _totalPages = 0;
    _currentPage = 0;
    _pageMargin = 0.0f;
    _pageSize = self.bounds.size;
    
    _allowScrollToPage = YES;

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                          action:@selector(tapGestureHandler:)];
    tap.numberOfTapsRequired = 1;
    tap.numberOfTouchesRequired = 1;
    
    [self addGestureRecognizer:tap];
    [tap release];
    
    //[self.scrollView.panGestureRecognizer requireGestureRecognizerToFail:longPress];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceiveMemoryWarning:)
                                                 name:UIApplicationDidReceiveMemoryWarningNotification
                                               object:nil];

}

- (void)awakeFromNib
{
    [self commonInit];
    [self reloadData];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
            // Initialization code
        [self commonInit];
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

- (RScrollView*)scrollView
{
    if (!_scrollView) {
        _scrollView = [[RScrollView alloc] initWithFrame:self.bounds];
        _scrollView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        _scrollView.pagingEnabled = YES;
        _scrollView.scrollEnabled = YES;
        _scrollView.clipsToBounds = NO;
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

- (void)setPageControlHidden:(BOOL)pageControlHidden
{
    [self setPageControlHidden:pageControlHidden
                      animated:NO];
}

- (void)setPageTitleAlignment:(RPageControlTitleAlignment)align
{
    self.pageControl.titleAlignment = align;
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
    
    if (_loopSlide) {
        
        CGFloat w = self.frame.size.width;
        _scrollView.contentInset = UIEdgeInsetsMake(0, 2*w, 0, 2*w);
        
    }
    else {
        _scrollView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
        [self collectReusableViews];
    }
    [self updateContentSize];
    [self loadNeededPages];
}

- (void)setPageSize:(CGSize)pageSize
{
    NSAssert(0.f < pageSize.width && pageSize.width <= self.bounds.size.width, @"The page width should be smaller than view width");
    
    if (!CGSizeEqualToSize(self.pageSize, pageSize)) {
        _pageSize = pageSize;
        _scrollView.frame = CGRectMake((CGRectGetWidth(self.bounds)-_pageSize.width-_pageMargin)/2, 
                                       (CGRectGetHeight(self.bounds)-_pageSize.height)/2,
                                       _pageSize.width+_pageMargin,_pageSize.height);
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
        _scrollView.frame = CGRectMake((CGRectGetWidth(self.bounds)-self.pageSize.width-_pageMargin)/2,
                                       (CGRectGetHeight(self.bounds)-self.pageSize.height)/2,
                                       self.pageSize.width+_pageMargin,self.pageSize.height);
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
    if (_totalPages == 0)
        return;
    
    for (NSInteger i = _currentPage-_extraPagesForLoopShow; i <= _currentPage+_extraPagesForLoopShow; ++i) {
        if (!self.loopSlide && !(0 <= i && i < _totalPages))
            continue;
        [self loadViewOfPageAtIndex:i];
    }
}

- (void)loadViewOfPageAtIndex:(NSInteger)index
{
    NSInteger indexToLoad = (index - index / _totalPages * _totalPages + _totalPages) % _totalPages;
    
    CGSize size = self.scrollView.bounds.size;
    UIView *view = [self viewOfPageAtIndex:index];
    if (!view) {
        view = [self.dataSource RSlideView:self
                        viewForPageAtIndex:indexToLoad];
        view.tag = indexToLoad + kSubviewTagOffset;
        view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.scrollView addSubview:view];
    }
    view.frame = CGRectMake(_pageMargin / 2 + size.width * index,
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
    
    _visibleNumberOfViewsPerPage = floorf((CGRectGetWidth(self.bounds) - _pageSize.width - _pageMargin) / (2 * (_pageSize.width + _pageMargin))) * 2 + 1;
    _extraPagesForLoopShow = ceilf(self.bounds.size.width / (2*(_pageMargin + _pageSize.width)));
    
    [self reloadData];
}

- (void)updateContentSize
{
    self.scrollView.contentSize = CGSizeMake(CGRectGetWidth(_scrollView.frame)*_totalPages,
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
    _currentPage = MAX(MIN(_totalPages - 1, _currentPage),0);
    
    self.pageControl.numberOfPages = _totalPages;
    self.pageControl.currentPage = _currentPage;
    
    [self updateContentSize];
    
    self.scrollView.contentOffset = CGPointMake(_scrollView.frame.size.width * _currentPage, 0);
    
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
        [self.scrollView setContentOffset:CGPointMake(_scrollView.frame.size.width*index, 0)
                                 animated:YES];
    }
}

- (void)scrollToPageOffset:(CGFloat)pageOffset
{
    CGPoint offset = CGPointMake(pageOffset*_scrollView.frame.size.width, 0);
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
    
    CGPoint offset = CGPointMake(_scrollView.frame.size.width*page, 0);
    
    [self.scrollView setContentOffset:offset
                             animated:YES];
}

#pragma mark - UIScrollView Delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
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
    if ([self.delegate respondsToSelector:@selector(RSlideViewDidEndScrollAnimation:)])
        [self.delegate RSlideViewDidEndScrollAnimation:self];
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
}

#pragma mark - UIGesture Delegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer 
       shouldReceiveTouch:(UITouch *)touch
{
    return NO;
}

@end


#define PAGE_CONTROL_PADDING 8.0f

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
        self.backgroundColor = [UIColor colorWithRed:0.f
                                               green:0.f
                                                blue:0.f
                                               alpha:0.6f];
        
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
        [_pageControl release];
        
    }
    return self;
}

- (UIView*)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    if (CGRectContainsPoint(self.bounds, point))
        return _pageControl;
    return nil;
}

- (void)onPageChanged:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(RPageControllDidChangePage:)]) {
        [self.delegate RPageControllDidChangePage:self];
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
            label.minimumFontSize = 10;
            label.textColor = [UIColor whiteColor];
            label.backgroundColor = [UIColor clearColor];
            label.lineBreakMode = UILineBreakModeMiddleTruncation;
            label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            [self addSubview:label];
            _titleLabel = label;
            [label release];
            
            self.titleAlignment = self.titleAlignment;
        }
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
    frame.size.width = [_pageControl sizeForNumberOfPages:numberOfPages].width;
    switch (titleAlignment) {
        case RPageControllTitleAlignLeft:
            frame.origin.x = self.bounds.size.width - frame.size.width - PAGE_CONTROL_PADDING;
            break;
        case RPageControllTitleAlignRight:
            frame.origin.x = PAGE_CONTROL_PADDING;
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
    frame.size.width = CGRectGetWidth(frame) - CGRectGetWidth(_pageControl.frame) - PAGE_CONTROL_PADDING * 2;
    switch (titleAlignment) {
        case RPageControllTitleAlignLeft:
            frame.origin.x = PAGE_CONTROL_PADDING;
            _titleLabel.frame = frame;
            _titleLabel.textAlignment = UITextAlignmentLeft;
            _pageControl.frame = CGRectMake(CGRectGetWidth(self.frame)-CGRectGetWidth(_pageControl.frame)-PAGE_CONTROL_PADDING,0,
                                            CGRectGetWidth(_pageControl.frame), CGRectGetHeight(_pageControl.frame));
            break;
        case RPageControllTitleAlignRight:
            frame.origin.x = CGRectGetWidth(_pageControl.frame)+PAGE_CONTROL_PADDING;
            _titleLabel.frame = frame;
            _titleLabel.textAlignment = UITextAlignmentRight;
            _pageControl.frame = CGRectMake(PAGE_CONTROL_PADDING, 0, _pageControl.frame.size.width,
                                            _pageControl.frame.size.height);
            break;
        default:
            break;
    }
}

@end

@implementation RScrollView

- (UIView*)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    for (UIView *view in self.subviews) {
        if (CGRectContainsPoint(view.frame, point))
            return [view hitTest:[self convertPoint:point
                                            toView:view]
                       withEvent:event];
    }
    return self;
}

@end
