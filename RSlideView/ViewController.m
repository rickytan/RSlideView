//
//  ViewController.m
//  RSlideView
//
//  Created by sheng tan on 12-4-7.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "ViewController.h"
#import <QuartzCore/QuartzCore.h>

@implementation ViewController
@synthesize heightSlider;

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    slideView = [[RSlideView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 160)];
    slideView.delegate = self;
    slideView.dataSource = self;
    [self.view addSubview:slideView];
    [slideView release];
    
    [slideView setPageControlHidden:NO
                           animated:YES];
    CGAffineTransform trans = CGAffineTransformMakeRotation(-M_PI_2);
    self.heightSlider.transform = trans;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

#pragma mark - RSlideView Datasource

- (NSInteger)RSlideViewNumberOfPages
{
    return 7;
}

- (UIView*)RSlideView:(RSlideView *)_slideView 
    viewForPageAtIndex:(NSInteger)index
{
    UIImageView *image = (UIImageView*)[_slideView dequeueReusableView];
    if (!image) {
        image = [[[UIImageView alloc] initWithFrame:_slideView.bounds] autorelease];

    }
    image.image = [UIImage imageNamed:[NSString stringWithFormat:@"%d.jpg",index]];
    return image;
}

- (NSString*)RSlideView:(RSlideView *)slideView titleForPageAtIndex:(NSInteger)index
{
    return [NSString stringWithFormat:@"Title for %d",index];
}

#pragma mark - RSlideView Delegate

- (void)RSlideView:(RSlideView *)_slideView tapOnPageAtIndex:(NSInteger)index
{
    [[[[UIAlertView alloc] initWithTitle:@"Click"
                                 message:[NSString stringWithFormat:@"You tapped on index %d",index]
                                delegate:nil
                       cancelButtonTitle:@"OK"
                       otherButtonTitles:nil] autorelease] show];
}

- (IBAction)onPrev:(id)sender
{
    [slideView previousPage];
}

- (IBAction)onNext:(id)sender
{
    [slideView nextPage];
}

- (IBAction)onPageWidth:(UISlider*)slider
{
    CGSize size = slideView.pageSize;
    size.width = slider.value;
    slideView.pageSize = size;
}

- (IBAction)onPageHeight:(UISlider*)slider
{
    CGSize size = slideView.pageSize;
    size.height = slider.value;
    slideView.pageSize = size;
}

- (IBAction)onPageMargin:(UISlider*)slider
{
    slideView.pageMargin = slider.value;
}

- (IBAction)onLoopscroll:(UISwitch*)sender
{
    slideView.loopSlide = sender.on;
}

- (IBAction)onContinuousscroll:(UISwitch*)sender
{
    slideView.continuousScroll = sender.on;
}

- (IBAction)onTitleAlignment:(UISwitch*)sender
{
    [slideView setPageTitleAlignment:sender.on?RPageControllTitleAlignRight:RPageControllTitleAlignLeft];
}
@end
