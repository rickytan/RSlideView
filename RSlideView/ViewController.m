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

- (NSInteger)RSlideViewNumberOfPages
{
    return 3;
}

- (UIView*)RSliderView:(RSlideView *)_slideView 
    viewForPageAtIndex:(NSInteger)index
{
    UIImageView *image = (UIImageView*)[_slideView dequeueReusableView];
    if (!image) {
        image = [[[UIImageView alloc] initWithFrame:_slideView.bounds] autorelease];
    }
    image.image = [UIImage imageNamed:[NSString stringWithFormat:@"%d.jpg",index]];
    return image;
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
