/*
 Copyright (c) 2013-14, Jimmy Dee
 All rights reserved.

 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "IOSKnobControl.h"
#import "KCDViewController.h"

@implementation KCDViewController {
    IOSKnobControl* knobControl;
    IOSKnobControl* minControl;
    IOSKnobControl* maxControl;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // basic IOSKnobControl initialization (using default settings) with an image from the bundle
    knobControl = [[IOSKnobControl alloc] initWithFrame:self.knobControlView.bounds imageNamed:@"hexagon-ccw"];

    // arrange to be notified whenever the knob turns
    [knobControl addTarget:self action:@selector(knobPositionChanged:) forControlEvents:UIControlEventValueChanged];

    // Now hook it up to the demo
    [self.knobControlView addSubview:knobControl];

    [self setupMinAndMaxControls];

    [self updateKnobProperties];

    if (knobControl.mode == IKCMContinuous) {
        self.indexLabel.hidden = YES;
        self.indexLabelLabel.hidden = YES;
    }
}

- (void)updateKnobProperties
{
    knobControl.mode = IKCMLinearReturn + self.modeControl.selectedSegmentIndex;
    knobControl.positions = self.positionsTextField.text.intValue;
    knobControl.circular = self.circularSwitch.on;
    knobControl.min = minControl.position;
    knobControl.max = maxControl.position;
    knobControl.clockwise = self.clockwiseSwitch.on;

    /*
     * The control ranges from -1 to 1, starting at 0. This avoids compressing the
     * scale in the range below 0.
     */
    knobControl.timeScale = exp(self.timeScaleControl.value);

    minControl.clockwise = maxControl.clockwise = knobControl.clockwise;

    minControl.position = minControl.position;
    maxControl.position = maxControl.position;

    knobControl.position = knobControl.position;

    // with the current hexagonal image for discrete mode, min and max don't make much sense
    minControl.enabled = maxControl.enabled = knobControl.mode == IKCMContinuous ? self.circularSwitch.on == NO : NO;
}

- (void)knobPositionChanged:(IOSKnobControl*)sender
{
    if (sender == knobControl) {
        self.positionLabel.text = [NSString stringWithFormat:@"%.2f", knobControl.position];

        if (knobControl.mode != IKCMContinuous) {
            self.indexLabel.text = [NSString stringWithFormat:@"%d", knobControl.positionIndex];
        }
    }
    else if (sender == minControl) {
        self.minLabel.text = [NSString stringWithFormat:@"%.2f", minControl.position];
        knobControl.min = minControl.position;
    }
    else if (sender == maxControl) {
        self.maxLabel.text = [NSString stringWithFormat:@"%.2f", maxControl.position];
        knobControl.max = maxControl.position;
    }
}

- (void)setupMinAndMaxControls
{
    // Both controls use the same image in continuous mode with circular set to NO. The clockwise
    // property is set to the same value as the main knob (the value of self.clockwiseSwitch.on).
    // That happens in updateKnobProperties.
    minControl = [[IOSKnobControl alloc] initWithFrame:self.minControlView.bounds];
    maxControl = [[IOSKnobControl alloc] initWithFrame:self.maxControlView.bounds];

    // Use the same three images for each knob.
    [minControl setImage:[UIImage imageNamed:@"teardrop"] forState:UIControlStateNormal];
    [minControl setImage:[UIImage imageNamed:@"teardrop-disabled"] forState:UIControlStateDisabled];
    [minControl setImage:[UIImage imageNamed:@"teardrop-highlighted"] forState:UIControlStateHighlighted];

    [maxControl setImage:[UIImage imageNamed:@"teardrop"] forState:UIControlStateNormal];
    [maxControl setImage:[UIImage imageNamed:@"teardrop-disabled"] forState:UIControlStateDisabled];
    [maxControl setImage:[UIImage imageNamed:@"teardrop-highlighted"] forState:UIControlStateHighlighted];

    minControl.mode = maxControl.mode = IKCMContinuous;
    minControl.circular = maxControl.circular = NO;

    // reuse the same knobPositionChanged: method
    [minControl addTarget:self action:@selector(knobPositionChanged:) forControlEvents:UIControlEventValueChanged];
    [maxControl addTarget:self action:@selector(knobPositionChanged:) forControlEvents:UIControlEventValueChanged];

    // the min. control ranges from -M_PI to 0 and starts at -0.5*M_PI
    minControl.min = -M_PI + 1e-7;
    minControl.max = 0.0;
    minControl.position = -M_PI_2;

    // the max. control ranges from 0 to M_PI and starts at 0.5*M_PI
    maxControl.min = 0.0;
    maxControl.max = M_PI - 1e-7;
    maxControl.position = M_PI_2;

    // add each to its placeholder
    [self.minControlView addSubview:minControl];
    [self.maxControlView addSubview:maxControl];
}

#pragma mark - Handlers for configuration controls

- (void)modeChanged:(UISegmentedControl *)sender
{
    NSLog(@"Mode index changed to %ld", (long)sender.selectedSegmentIndex);
    IKCMode mode = IKCMLinearReturn + (int)sender.selectedSegmentIndex;

    /*
     * Specification of animation and positions only applies to discrete mode.
     * Index is only displayed in discrete mode. Adjust accordingly, depending
     * on mode.
     */
    switch (mode) {
        case IKCMLinearReturn:
        case IKCMWheelOfFortune:
            // for now, always use a hexagonal image, so positions is always 6
            // circular is always YES
            // self.positionsTextField.enabled = YES;
            self.positionsTextField.enabled = NO;
            self.indexLabelLabel.hidden = NO;
            self.indexLabel.hidden = NO;
            self.circularSwitch.on = YES;
            self.circularSwitch.enabled = NO;
            self.timeScaleControl.enabled = YES;

            [knobControl setImage:[UIImage imageNamed:self.clockwiseSwitch.on ? @"hexagon-cw" : @"hexagon-ccw"] forState:UIControlStateNormal];
            [knobControl setImage:nil forState:UIControlStateHighlighted];

            NSLog(@"Switched to discrete mode");
            break;
        case IKCMContinuous:
            self.positionsTextField.enabled = NO;
            self.indexLabelLabel.hidden = YES;
            self.indexLabel.hidden = YES;
            self.circularSwitch.enabled = YES;
            self.timeScaleControl.enabled = NO;

            [knobControl setImage:[UIImage imageNamed:@"teardrop"] forState:UIControlStateNormal];
            [knobControl setImage:[UIImage imageNamed:@"teardrop-highlighted"] forState:UIControlStateHighlighted];
            [knobControl setImage:[UIImage imageNamed:@"teardrop-disabled"] forState:UIControlStateDisabled];
            // [knobControl setImage:[UIImage imageNamed:@"knob"] forState:UIControlStateSelected];

            NSLog(@"Switched to continuous mode");
            break;
        default:
            NSLog(@"Error: unsupported mode selected");
            abort();
    }

    [self updateKnobProperties];
}

- (void)circularChanged:(UISwitch *)sender
{
    NSLog(@"Circular is %@", (sender.on ? @"YES" : @"NO"));
    [self updateKnobProperties];
}

- (void)clockwiseChanged:(UISwitch *)sender
{

    switch (knobControl.mode) {
        case IKCMLinearReturn:
        case IKCMWheelOfFortune:
            [knobControl setImage:[UIImage imageNamed:self.clockwiseSwitch.on ? @"hexagon-cw" : @"hexagon-ccw"] forState:UIControlStateNormal];
            break;
        default:
            break;
    }

    [self updateKnobProperties];
}

- (void)timeScaleChanged:(UISlider *)sender
{
    [self updateKnobProperties];
}

@end
