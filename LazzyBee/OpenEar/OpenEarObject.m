//
//  OpenEarObject.m
//  LazzyBee
//
//  Created by HuKhong on 10/15/15.
//  Copyright © 2015 Born2go. All rights reserved.
//

#import "OpenEarObject.h"
#import <OpenEars/OEPocketsphinxController.h>
#import <OpenEars/OEFliteController.h>
#import <OpenEars/OELanguageModelGenerator.h>
#import <OpenEars/OELogging.h>
#import <OpenEars/OEAcousticModel.h>
#import <Slt/Slt.h>
#import <AVFoundation/AVFoundation.h>

#define OFFSET 5
#define OPEN_EAR_IS_OFF @"Open Ear is off"
#define OPEN_EAR_IS_ON @"Open Ear is on"

@interface OpenEarObject()
{
    AVSpeechSynthesizer *synthesizer;
}

// These three are the important OpenEars objects that this class demonstrates the use of.
@property (nonatomic, strong) Slt *slt;

@property (nonatomic, strong) OEEventsObserver *openEarsEventsObserver;
@property (nonatomic, strong) OEPocketsphinxController *pocketsphinxController;
@property (nonatomic, strong) OEFliteController *fliteController;

@property (nonatomic, assign) int restartAttemptsDueToPermissionRequests;
@property (nonatomic, assign) BOOL startupFailedDueToLackOfPermissions;

@property (nonatomic, copy) NSString *pathToFirstDynamicallyGeneratedLanguageModel;
@property (nonatomic, copy) NSString *pathToFirstDynamicallyGeneratedDictionary;

@end

@implementation OpenEarObject
{
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [[NSBundle mainBundle] loadNibNamed:@"OpenEarObject" owner:self options:nil];
        CGRect rect = self.view.frame;
        rect.size.height = frame.size.height;
        rect.size.width = frame.size.width;
        [self.view setFrame:rect];
        
        self.view.layer.masksToBounds = NO;
        self.view.layer.shadowOffset = CGSizeMake(-5, 10);
        self.view.layer.shadowRadius = 5;
        self.view.layer.shadowOpacity = 0.5;
        
        [self addSubview:self.view];

        self.fliteController = [[OEFliteController alloc] init];
        self.openEarsEventsObserver = [[OEEventsObserver alloc] init];
        self.openEarsEventsObserver.delegate = self;
        self.slt = [[Slt alloc] init];
        
        self.restartAttemptsDueToPermissionRequests = 0;
        self.startupFailedDueToLackOfPermissions = FALSE;
        
        [OELogging startOpenEarsLogging]; // Uncomment me for OELogging, which is verbose logging about internal OpenEars operations such as audio settings. If you have issues, show this logging in the forums.
        [OEPocketsphinxController sharedInstance].verbosePocketSphinx = TRUE; // Uncomment this for much more verbose speech recognition engine output. If you have issues, show this logging in the forums.
        
        [self.openEarsEventsObserver setDelegate:self]; // Make this class the delegate of OpenEarsObserver so we can get all of the messages about what OpenEars is doing.
        
        [[OEPocketsphinxController sharedInstance] setActive:TRUE error:nil]; // Call this before setting any OEPocketsphinxController characteristics
        
        // This is the language model we're going to start up with. The only reason I'm making it a class property is that I reuse it a bunch of times in this example,
        // but you can pass the string contents directly to OEPocketsphinxController:startListeningWithLanguageModelAtPath:dictionaryAtPath:languageModelIsJSGF:
        
        NSArray *firstLanguageArray = @[COMMAND_SHOW_ANSWER, // There is no case requirement in OpenEars,
                                        COMMAND_LEARN_AGAIN, // so these can be uppercase, lowercase, or mixed case.
                                        COMMAND_EASY,
                                        COMMAND_NORMAL,
                                        COMMAND_HARD,
                                        COMMAND_PRONOUNCE,
                                        COMMAND_MEANING,
                                        COMMAND_EXAMPLE];
        
        OELanguageModelGenerator *languageModelGenerator = [[OELanguageModelGenerator alloc] init];
        
        // languageModelGenerator.verboseLanguageModelGenerator = TRUE; // Uncomment me for verbose language model generator debug output.
        
        NSError *error = [languageModelGenerator generateLanguageModelFromArray:firstLanguageArray withFilesNamed:@"FirstOpenEarsDynamicLanguageModel" forAcousticModelAtPath:[OEAcousticModel pathToModel:@"AcousticModelEnglish"]]; // Change "AcousticModelEnglish" to "AcousticModelSpanish" in order to create a language model for Spanish recognition instead of English.
        
        
        if(error) {
            NSLog(@"Dynamic language generator reported error %@", [error description]);
        } else {
            self.pathToFirstDynamicallyGeneratedLanguageModel = [languageModelGenerator pathToSuccessfullyGeneratedLanguageModelWithRequestedName:@"FirstOpenEarsDynamicLanguageModel"];
            self.pathToFirstDynamicallyGeneratedDictionary = [languageModelGenerator pathToSuccessfullyGeneratedDictionaryWithRequestedName:@"FirstOpenEarsDynamicLanguageModel"];
            
            [[OEPocketsphinxController sharedInstance] setActive:TRUE error:nil]; // Call this once before setting properties of the OEPocketsphinxController instance.
            
            //   [OEPocketsphinxController sharedInstance].pathToTestFile = [[NSBundle mainBundle] pathForResource:@"change_model_short" ofType:@"wav"];  // This is how you could use a test WAV (mono/16-bit/16k) rather than live recognition. Don't forget to add your WAV to your app bundle.
            
            if(![OEPocketsphinxController sharedInstance].isListening) {
                [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:self.pathToFirstDynamicallyGeneratedLanguageModel dictionaryAtPath:self.pathToFirstDynamicallyGeneratedDictionary acousticModelAtPath:[OEAcousticModel pathToModel:@"AcousticModelEnglish"] languageModelIsJSGF:FALSE]; // Start speech recognition if we aren't already listening.
            }
        }
        
    }
    return self;
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
//- (void)drawRect:(CGRect)rect {
//    // Drawing code
//}

- (IBAction)panGestureHandle:(id)sender {
    CGPoint translation = [(UIPanGestureRecognizer*)sender translationInView:self.superview];
    [self setCenter:CGPointMake([self center].x + translation.x,
                                         [self center].y + translation.y)];
    [(UIPanGestureRecognizer*)sender setTranslation:CGPointMake(0, 0) inView:self.view];
    
    if ([(UIPanGestureRecognizer*)sender state] == UIGestureRecognizerStateEnded) {
        [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            CGPoint center = [self center];
            
            if (center.x > self.superview.frame.size.width/2) {
                center.x = self.superview.frame.size.width - self.view.frame.size.width/2 - OFFSET; //5 :: offset
                
            } else {
                center.x = self.view.frame.size.width/2 + OFFSET;
            }
            
            if (center.y > self.superview.frame.size.height - self.view.frame.size.height/2 - OFFSET) {
                center.y = self.superview.frame.size.height - self.view.frame.size.height/2 - OFFSET; //5 :: offset
                
            } else if (center.y < self.view.frame.size.height/2 + OFFSET) {
                center.y = self.view.frame.size.height/2 + 5;
            }
            
            [self setCenter:center];
        } completion:nil];
        
    }
}

- (IBAction)tapGestureHandle:(id)sender {
    if([OEPocketsphinxController sharedInstance].isListening) {
        [[OEPocketsphinxController sharedInstance] stopListening]; // React to it by telling Pocketsphinx to stop listening (if it is listening) since it will need to restart its loop after an interruption.
//        
//        [self playVoiceWithText:OPEN_EAR_IS_OFF];
        
    } else {
        [self startListening];
        
    }
}


- (void)playVoiceWithText:(NSString *) text {
    if (text != nil && text.length > 0) {
        
        [self textToSpeech:text];
    }
}
// This is an optional delegate method of OEEventsObserver which delivers the text of speech that Pocketsphinx heard and analyzed, along with its accuracy score and utterance ID.
- (void) pocketsphinxDidReceiveHypothesis:(NSString *)hypothesis recognitionScore:(NSString *)recognitionScore utteranceID:(NSString *)utteranceID {
    
    [[OEPocketsphinxController sharedInstance] suspendRecognition];
    NSLog(@"Local callback: The received hypothesis is %@ with a score of %@ and an ID of %@", hypothesis, recognitionScore, utteranceID); // Log it.
    if([hypothesis isEqualToString:COMMAND_EXAMPLE] ||
       [hypothesis isEqualToString:COMMAND_MEANING] ||
       [hypothesis isEqualToString:COMMAND_PRONOUNCE] ||
       [hypothesis isEqualToString:COMMAND_HARD] ||
       [hypothesis isEqualToString:COMMAND_NORMAL] ||
       [hypothesis isEqualToString:COMMAND_EASY] ||
       [hypothesis isEqualToString:COMMAND_LEARN_AGAIN] ||
       [hypothesis isEqualToString:COMMAND_SHOW_ANSWER]) {
        
        // This is how to use an available instance of OEFliteController. We're going to repeat back the command that we heard with the voice we've chosen.
        //    [self.fliteController say:[NSString stringWithFormat:@"%@",hypothesis] withVoice:self.slt];
        [self playVoiceWithText:hypothesis];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"OpenEarSendCommand" object:hypothesis];
    }
}

// An optional delegate method of OEEventsObserver which informs that there was an interruption to the audio session (e.g. an incoming phone call).
- (void) audioSessionInterruptionDidBegin {
    NSLog(@"Local callback:  AudioSession interruption began."); // Log it.
//    self.statusTextView.text = @"Status: AudioSession interruption began."; // Show it in the status box.
    self.view.userInteractionEnabled = NO;
    
    NSError *error = nil;
    if([OEPocketsphinxController sharedInstance].isListening) {
        error = [[OEPocketsphinxController sharedInstance] stopListening]; // React to it by telling Pocketsphinx to stop listening (if it is listening) since it will need to restart its loop after an interruption.
        if(error) NSLog(@"Error while stopping listening in audioSessionInterruptionDidBegin: %@", error);
    }
}

// An optional delegate method of OEEventsObserver which informs that the interruption to the audio session ended.
- (void) audioSessionInterruptionDidEnd {
    NSLog(@"Local callback:  AudioSession interruption ended."); // Log it.
//    self.statusTextView.text = @"Status: AudioSession interruption ended."; // Show it in the status box.
    
    self.view.userInteractionEnabled = YES;
    
    // We're restarting the previously-stopped listening loop.
    if(![OEPocketsphinxController sharedInstance].isListening){
        [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:self.pathToFirstDynamicallyGeneratedLanguageModel dictionaryAtPath:self.pathToFirstDynamicallyGeneratedDictionary acousticModelAtPath:[OEAcousticModel pathToModel:@"AcousticModelEnglish"] languageModelIsJSGF:FALSE]; // Start speech recognition if we aren't currently listening.
    }
}

// An optional delegate method of OEEventsObserver which informs that Pocketsphinx is now listening for speech.
- (void) pocketsphinxDidStartListening {
    
    NSLog(@"Local callback: Pocketsphinx is now listening."); // Log it.
    [self playVoiceWithText:OPEN_EAR_IS_ON];
    [imgEar setImage:[UIImage imageNamed:@"ic_ear"]];
    
}

// An optional delegate method of OEEventsObserver which informs that Pocketsphinx detected speech and is starting to process it.
- (void) pocketsphinxDidDetectSpeech {
    NSLog(@"Local callback: Pocketsphinx has detected speech."); // Log it.
}

// An optional delegate method of OEEventsObserver which informs that Pocketsphinx detected a second of silence, indicating the end of an utterance.
// This was added because developers requested being able to time the recognition speed without the speech time. The processing time is the time between
// this method being called and the hypothesis being returned.
- (void) pocketsphinxDidDetectFinishedSpeech {
    NSLog(@"Local callback: Pocketsphinx has detected a second of silence, concluding an utterance."); // Log it.
}

// An optional delegate method of OEEventsObserver which informs that Pocketsphinx has exited its recognition loop, most
// likely in response to the OEPocketsphinxController being told to stop listening via the stopListening method.
- (void) pocketsphinxDidStopListening {
    NSLog(@"Local callback: Pocketsphinx has stopped listening."); // Log it.
    [self playVoiceWithText:OPEN_EAR_IS_OFF];
    [imgEar setImage:[UIImage imageNamed:@"ic_ear_off"]];
    
}

// An optional delegate method of OEEventsObserver which informs that Pocketsphinx is still in its listening loop but it is not
// Going to react to speech until listening is resumed.  This can happen as a result of Flite speech being
// in progress on an audio route that doesn't support simultaneous Flite speech and Pocketsphinx recognition,
// or as a result of the OEPocketsphinxController being told to suspend recognition via the suspendRecognition method.
- (void) pocketsphinxDidSuspendRecognition {
    NSLog(@"Local callback: Pocketsphinx has suspended recognition."); // Log it.
//    [self playVoiceWithText:@"OpenEar is Suspended"];
    [imgEar setImage:[UIImage imageNamed:@"ic_ear_off"]];
}

// An optional delegate method of OEEventsObserver which informs that Pocketsphinx is still in its listening loop and after recognition
// having been suspended it is now resuming.  This can happen as a result of Flite speech completing
// on an audio route that doesn't support simultaneous Flite speech and Pocketsphinx recognition,
// or as a result of the OEPocketsphinxController being told to resume recognition via the resumeRecognition method.
- (void) pocketsphinxDidResumeRecognition {
    NSLog(@"Local callback: Pocketsphinx has resumed recognition."); // Log it.
//    [self playVoiceWithText:@"OpenEar is resumed"];
    [imgEar setImage:[UIImage imageNamed:@"ic_ear"]];
}

/** Pocketsphinx couldn't start because it has no mic permissions (will only be returned on iOS7 or later).*/
- (void) pocketsphinxFailedNoMicPermissions {
    NSLog(@"Local callback: The user has never set mic permissions or denied permission to this app's mic, so listening will not start.");
    self.startupFailedDueToLackOfPermissions = TRUE;
    
    if([OEPocketsphinxController sharedInstance].isListening){
        NSError *error = [[OEPocketsphinxController sharedInstance] stopListening]; // Stop listening if we are listening.
        if(error) NSLog(@"Error while stopping listening in micPermissionCheckCompleted: %@", error);
    }
}

/** The user prompt to get mic permissions, or a check of the mic permissions, has completed with a TRUE or a FALSE result  (will only be returned on iOS7 or later).*/
- (void) micPermissionCheckCompleted:(BOOL)result {
    if(result) {
        self.restartAttemptsDueToPermissionRequests++;
        if(self.restartAttemptsDueToPermissionRequests == 1 && self.startupFailedDueToLackOfPermissions) { // If we get here because there was an attempt to start which failed due to lack of permissions, and now permissions have been requested and they returned true, we restart exactly once with the new permissions.
            
            if(![OEPocketsphinxController sharedInstance].isListening) { // If there was no error and we aren't listening, start listening.
                [[OEPocketsphinxController sharedInstance]
                 startListeningWithLanguageModelAtPath:self.pathToFirstDynamicallyGeneratedLanguageModel
                 dictionaryAtPath:self.pathToFirstDynamicallyGeneratedDictionary
                 acousticModelAtPath:[OEAcousticModel pathToModel:@"AcousticModelEnglish"]
                 languageModelIsJSGF:FALSE]; // Start speech recognition.
                
                self.startupFailedDueToLackOfPermissions = FALSE;
            }
        }
    }
}

- (void)stopListening {
    if([OEPocketsphinxController sharedInstance].isListening){
        [[OEPocketsphinxController sharedInstance] stopListening];
    }
    
    self.openEarsEventsObserver.delegate = nil;
    self.delegate = nil;
}

- (void)startListening {
    if ([OEPocketsphinxController sharedInstance].micPermission == YES) {
        [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:self.pathToFirstDynamicallyGeneratedLanguageModel dictionaryAtPath:self.pathToFirstDynamicallyGeneratedDictionary acousticModelAtPath:[OEAcousticModel pathToModel:@"AcousticModelEnglish"] languageModelIsJSGF:FALSE]; // Start speech recognition if we aren't currently listening.
        
        self.startupFailedDueToLackOfPermissions = FALSE;
        
        //        [self playVoiceWithText:OPEN_EAR_IS_ON];
    }
}

- (void)textToSpeech:(NSString *)text {
//    if (!synthesizer) {
//        synthesizer = [[AVSpeechSynthesizer alloc]init];
//    }
//    
//    [synthesizer stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
//    
//    AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:text];
//    
//    [utterance setRate:0.35];
//    [synthesizer speakUtterance:utterance];
}
@end
