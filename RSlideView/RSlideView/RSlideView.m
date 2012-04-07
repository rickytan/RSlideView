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

@implementation RSlideView
@synthesize pageControl = _pageControl;
@synthesize scrollView = _scrollView;
@synthesize delegate = _delegate;
@synthesize dataSource = _dataSource;
@synthesize loopSlide = _loopSlide,continuousScroll = _continuousScroll,pageControlHidden = _pageControlHidden;

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
        
        CGRect frame = self.pageControl.frame;
        frame.origin = CGPointMake(0, frame.size.height - 24.f);
        frame.size = CGSizeMake(frame.size.width, 24.f);
        self.pageControl.frame = frame;
        [self addSubview:self.pageControl];
        
        _reusableViews = [[NSMutableArray alloc] initWithCapacity:16];
        _visibleNumberOfViewsPerPage = 1;
        _totalPages = 0;
        _currentPage = 0;
        
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressGestureHandler:)];
        longPress.numberOfTouchesRequired = 1;
        longPress.minimumPressDuration = 0.12;
        [self addGestureRecognizer:longPress];
        [longPress release];
        
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

- (UIPageControl*)pageControl
{
    if (!_pageControl) {
        _pageControl = [[UIPageControl alloc] initWithFrame:self.bounds];
        _pageControl.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
        _pageControl.hidesForSinglePage = YES;
        _pageControl.defersCurrentPageDisplay = YES;
        [_pageControl addTarget:self
                         action:@selector(onPageControlValueChange:)
               forControlEvents:UIControlEventValueChanged];
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
        _scrollView.bounces = NO;
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
    
    self.scrollView.pagingEnabled = !_continuousScroll;
}

- (void)setLoopSlide:(BOOL)loopSlide
{
    if (_loopSlide == loopSlide)
        return;
    
    _loopSlide = loopSlide;
    
    if (_loopSlide) {
        CGFloat width = self.scrollView.frame.size.width;
        self.scrollView.contentInset = UIEdgeInsetsMake(0, width, 0, width);
        if (_currentPage == 0)
            [self loadViewOfPageAtIndex:-1];
        else if (_currentPage == _totalPages - 1)
            [self loadViewOfPageAtIndex:_totalPages];
    }
    else {
        self.scrollView.contentInset = UIEdgeInsetsZero;
        [self clearUpandMakeReusableAtIndex:-1];
        [self clearUpandMakeReusableAtIndex:_totalPages];
    }
}

#pragma mark - Private Methods

- (void)loadNeededPages
{
    for (NSInteger i = _currentPage-1; i <= _currentPage+1; ++i) {
        if (!self.loopSlide && !(0 <= i && i < _totalPages))
            continue;
        [self loadViewOfPageAtIndex:i];
    }
}

- (void)loadViewOfPageAtIndex:(NSInteger)index
{
    NSInteger indexToLoad = index;
    if (indexToLoad < 0)
        indexToLoad = _totalPages - 1;
    else if (indexToLoad > _totalPages - 1)
        indexToLoad = 0;
    
    CGSize size = self.scrollView.bounds.size;
    UIView *view = [self viewOfPageAtIndex:index];
    if (!view) {
        view = [self.dataSource RSliderView:self
                         viewForPageAtIndex:indexToLoad];
        view.frame = CGRectMake(size.width * index, 0, size.width, size.height);
        view.tag = index + kSubviewTagOffset;
        view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.scrollView addSubview:view];
    }
}

- (void)collectReusableViews
{
    for (int i=-1; i<=_currentPage-2; i++) {
        [self clearUpandMakeReusableAtIndex:i];
    }
    for (int i=_currentPage+2; i<=_totalPages; i++) {
        [self clearUpandMakeReusableAtIndex:i];
    }
}

- (void)clearUpandMakeReusableAtIndex:(NSInteger)index
{
    UIView *view = [self viewOfPageAtIndex:index];
    if (view) {
        view.tag = kSubviewInvalidTagOffset;
        [_reusableViews addObject:view];
        [view removeFromSuperview];
    }
}

- (void)updateScrollViewOffset
{
    
}

- (void)adjustScrollViewOffsetToSinglePage
{
    CGFloat width = self.scrollView.frame.size.width;
    self.pageControl.currentPage = _currentPage;
    [self.scrollView setContentOffset:CGPointMake(_currentPage*width, 0) animated:YES];
}

- (void)onPageControlValueChange:(id)sender
{
    NSInteger page = self.pageControl.currentPage;
    
    CGFloat width = self.scrollView.bounds.size.width;
    CGPoint offset = CGPointMake(width*page, 0);
    
    [self.scrollView setContentOffset:offset animated:YES];
        //self.pageControl.currentPage = page;
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
    _currentPage = 0;
    
    self.pageControl.numberOfPages = _totalPages;
    self.pageControl.currentPage = _currentPage;
    
    self.scrollView.contentSize = CGSizeMake(self.scrollView.bounds.size.width * _totalPages,
                                             self.scrollView.bounds.size.height);
    self.scrollView.contentOffset = CGPointZero;
    
    [self loadNeededPages];
}

- (UIView*)dequeueReusableView
{
    UIView *reuse = nil;
    @try {
        reuse = [[_reusableViews lastObject] retain];
        [_reusableViews removeLastObject];
    }
    @catch (NSException *exception) {
            //
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
    CGFloat width = self.scrollView.bounds.size.width;
    [self.scrollView setContentOffset:CGPointMake(width*index, 0)
                             animated:YES];
}

#pragma mark - UIScrollView Delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat width = self.scrollView.bounds.size.width;
    CGFloat halfWidth = width / 2.f;
    
    NSInteger displayingPage = floorf((scrollView.contentOffset.x + halfWidth) / width);
    
    if (displayingPage != _currentPage) {   // have to load new page
        _currentPage = displayingPage;
        
        CGPoint offset = self.scrollView.contentOffset;
        if (_currentPage == -1) {
            _currentPage = _totalPages - 1;
            offset.x += width * _totalPages;
            self.scrollView.contentOffset = offset;
        }
        else if (_currentPage == _totalPages) {
            _currentPage = 0;
            offset.x -= width * _totalPages;
            self.scrollView.contentOffset = offset;
        }
        [self collectReusableViews]; 
        [self loadNeededPages];
    }
    self.pageControl.currentPage = _currentPage;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView 
                     withVelocity:(CGPoint)velocity 
              targetContentOffset:(inout CGPoint *)targetContentOffset
{
    
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView 
                  willDecelerate:(BOOL)decelerate
{
    
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView
{
    
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    if (self.continuousScroll) {
        [self adjustScrollViewOffsetToSinglePage];
    }
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{

}

@end
