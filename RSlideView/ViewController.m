//
//  ViewController.m
//  RSlideView
//
//  Created by sheng tan on 12-4-7.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "ViewController.h"

@implementation ViewController

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
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

#pragma mark - RSlideView Datasource

- (NSInteger)RSlideViewNumberOfPages
{
    return 3;
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

- (void)RSlideView:(RSlideView *)_slideView tapStartOnPageAtIndex:(NSInteger)index
{
    UIImageView *image = (UIImageView*)[_slideView viewOfPageAtIndex:index];
    image.alpha = 0.5;
}

- (void)RSlideView:(RSlideView *)_slideView tapEndOnPageAtIndex:(NSInteger)index
{
    UIImageView *image = (UIImageView*)[_slideView viewOfPageAtIndex:index];
    image.alpha = 1.0;
}

- (IBAction)onPrev:(id)sender
{
    [slideView previousPage];
}

- (IBAction)onNext:(id)sender
{
    [slideView nextPage];
}

- (IBAction)onLoopscroll:(UISwitch*)sender
{
    slideView.loopSlide = sender.on;
}

- (IBAction)onContinuousscroll:(UISwitch*)sender
{
    slideView.continuousScroll = sender.on;
}

@end
