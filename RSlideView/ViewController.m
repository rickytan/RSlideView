//
//  ViewController.m
//  RSlideView
//
//  Created by sheng tan on 12-4-7.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "ViewController.h"
#import <QuartzCore/QuartzCore.h>

@interface ViewController ()
<RSlideViewDelegate,RSlideViewDataSource>

@property (nonatomic, weak) IBOutlet UISlider *heightSlider;
@property (nonatomic, weak) IBOutlet UISlider *pageWidthSlider;
@property (nonatomic, weak) IBOutlet RSlideView *slideView;

- (IBAction)onPrev:(id)sender;
- (IBAction)onNext:(id)sender;
- (IBAction)onPageWidth:(id)sender;
- (IBAction)onPageHeight:(id)sender;
- (IBAction)onPageMargin:(id)sender;
- (IBAction)onLoopscroll:(id)sender;
- (IBAction)onContinuousscroll:(id)sender;
- (IBAction)onTitleAlignment:(id)sender;

@end

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
    
    [self.slideView setPageControlHidden:NO
                           animated:YES];
    [self.slideView reloadData];
    
    CGAffineTransform trans = CGAffineTransformMakeRotation(-M_PI_2);
    self.heightSlider.transform = trans;

}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    self.pageWidthSlider.maximumValue = self.view.bounds.size.width;
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

- (UIView*)RSlideView:(RSlideView *)slideView
    viewForPageAtIndex:(NSInteger)index
{
    UIImageView *image = (UIImageView*)[_slideView dequeueReusableView];
    if (!image) {
        image = [[UIImageView alloc] initWithFrame:_slideView.bounds];
        image.contentMode = UIViewContentModeScaleToFill;
    }
    image.image = [UIImage imageNamed:[NSString stringWithFormat:@"%ld.jpg",index]];
    return image;
}

- (NSString*)RSlideView:(RSlideView *)slideView titleForPageAtIndex:(NSInteger)index
{
    return [NSString stringWithFormat:@"Title for %ld",index];
}

#pragma mark - RSlideView Delegate

- (void)RSlideView:(RSlideView *)_slideView tapOnPageAtIndex:(NSInteger)index
{
    [[[UIAlertView alloc] initWithTitle:@"Click"
                                 message:[NSString stringWithFormat:@"You tapped on index %ld",index]
                                delegate:nil
                       cancelButtonTitle:@"OK"
                       otherButtonTitles:nil] show];
}

- (IBAction)onPrev:(id)sender
{
    [self.slideView previousPage];
}

- (IBAction)onNext:(id)sender
{
    [self.slideView nextPage];
}

- (IBAction)onPageWidth:(UISlider*)slider
{
    CGSize size = self.slideView.pageSize;
    size.width = slider.value;
    self.slideView.pageSize = size;
}

- (IBAction)onPageHeight:(UISlider*)slider
{
    CGSize size = self.slideView.pageSize;
    size.height = slider.value;
    self.slideView.pageSize = size;
}

- (IBAction)onPageMargin:(UISlider*)slider
{
    self.slideView.pageMargin = slider.value;
}

- (IBAction)onLoopscroll:(UISwitch*)sender
{
    self.slideView.loopSlide = sender.on;
}

- (IBAction)onContinuousscroll:(UISwitch*)sender
{
    self.slideView.continuousScroll = sender.on;
}

- (IBAction)onTitleAlignment:(UISwitch*)sender
{
    [self.slideView setPageTitleAlignment:sender.on ? RPageControllTitleAlignRight:RPageControllTitleAlignLeft];
}
@end
