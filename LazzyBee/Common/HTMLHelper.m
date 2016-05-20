//
//  HTMLHelper.m
//  LazzyBee
//
//  Created by HuKhong on 4/19/15.
//  Copyright (c) 2015 HuKhong. All rights reserved.
//

#import "HTMLHelper.h"
#import "UIKit/UIKit.h"
#import "sqlite3.h"
#import "Common.h"
#import "LocalizeHelper.h"

// Singleton
static HTMLHelper* sharedHTMLHelper = nil;

@implementation HTMLHelper


//-------------------------------------------------------------
// allways return the same singleton
//-------------------------------------------------------------
+ (HTMLHelper*) sharedHTMLHelper {
    // lazy instantiation
    if (sharedHTMLHelper == nil) {
        sharedHTMLHelper = [[HTMLHelper alloc] init];
    }
    return sharedHTMLHelper;
}


//-------------------------------------------------------------
// initiating
//-------------------------------------------------------------
- (id) init {
    self = [super init];
    if (self) {
        // use systems main bundle as default bundle
    }
    return self;
}

- (NSString *)createHTMLForQuestion:(WordObject *)word withPackage:(MajorObject *)majorObj {
    NSString *package = @"";
    NSString *packageLowcase = @"";
    
    if (majorObj) {
        package = [NSString stringWithFormat:@"[%@]", [majorObj displayName]];
        packageLowcase = [majorObj.majorName lowercaseString];
        
    } else {
        packageLowcase = @"common";
    }
    
    if (![packageLowcase isEqualToString:@"common"]) {

        //parse the answer to dictionary object
        NSData *data = [word.answers dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *dictAnswer = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        
        //A word may has many meanings corresponding to many fields (common, it, economic...)
        //The meaning of each field is considered as a package
        NSDictionary *dictPackages = [dictAnswer valueForKey:@"packages"];
        NSDictionary *dictSinglePackage = [dictPackages valueForKey:packageLowcase];
        
        if (dictSinglePackage == nil) {
            
            package = @"";
        }
    }
    
    NSString *htmlString = @"<!DOCTYPE html>\n"
                            "<html>\n"
                            "<head>\n"
                                "<style>\n"
                                    "figure {"
                                    "   text-align: center;"
                                    "   margin: auto;"
                                    "}"
                                    "figure.image img {"
                                    "   width: 100%% !important;"
                                    "   height: auto !important;"
                                    "}"
                                    "figcaption {"
                                    "   font-size: 10px;"
                                    "}"
                                    "a {"
                                    "   margin-top:10px;"
                                    "}"
                                "</style>\n"
                                "<script>"
                                    //play the text
                                    "function playText(content, rate) {"
                                    "   var speaker = new SpeechSynthesisUtterance();"
                                    "   speaker.text = content;"
                                    "   speaker.lang = 'en-US';"
                                    "   speaker.rate = rate;" //0.1
                                    "   speaker.pitch = 1.0;"
                                    "   speaker.volume = 1.0;"
                                    "   speechSynthesis.cancel();"
                                    "   speechSynthesis.speak(speaker);"
                                    "}"
                                    //cancel speech
                                    "function cancelSpeech() {"
                                    "   speechSynthesis.pause();"
                                    "   speechSynthesis.cancel();"
                                    "}"
                                "</script>"
                            "</head>\n"
                            "<body>\n"
                                "<div style='width:100%%'>\n"
                                "%@\n"  //strWordIconTag
                                "</div>\n"
                            "</body>\n"
                            "</html>";
    
    NSNumber *speedNumberObj = [[Common sharedCommon] loadDataFromUserDefaultStandardWithKey:KEY_SPEAKING_SPEED];
    float speed = 2*[speedNumberObj floatValue];
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 9.0) {
        speed = speed/2;
    }
    
    NSString *strWordIconTag = @"<div style='float:left;width:90%%;text-align: center;'>\n"
                        "<strong style='font-size:18pt;'> %@ </strong>\n"   //%@ will be replaced by word.question
                        "</div>\n"
                        "<div style='float:left;width:10%%'>\n"
                        "<a onclick='playText(\"%@\", %f);'><img src='ic_speaker.png'/><p>\n"
                        "</div>\n"
                        "<div style='width:90%%'>"
                        "<center>%@</center>"
                        "</div>";
    
    strWordIconTag = [NSString stringWithFormat:strWordIconTag, word.question, word.question, speed, package];
    
    htmlString = [NSString stringWithFormat:htmlString, strWordIconTag];
    
    return htmlString;
}

- (NSString *)createHTMLForAnswer:(WordObject *)word withPackage:(MajorObject *)majorObj {
    NSString *htmlString = @"";
    NSString *imageLink = @"";
    NSString *package = @"";
    NSString *packageLowcase = @"";
    
    if (majorObj) {
        package = [NSString stringWithFormat:@"[%@]", [majorObj displayName]];
        packageLowcase = [majorObj.majorName lowercaseString];
        
    } else {
        packageLowcase = @"common";
    }
    
    //parse the answer to dictionary object
    NSData *data = [word.answers dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *dictAnswer = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    NSString *strPronounciation = [dictAnswer valueForKey:@"pronoun"];
    
    if ([strPronounciation isEqualToString:@"//"]) {
        strPronounciation = @"";
    }
    
    //A word may has many meanings corresponding to many fields (common, it, economic...)
    //The meaning of each field is considered as a package
    NSDictionary *dictPackages = [dictAnswer valueForKey:@"packages"];
    NSDictionary *dictSinglePackage = [dictPackages valueForKey:packageLowcase];
    
    if (dictSinglePackage == nil) {
        dictSinglePackage = [dictPackages valueForKey:@"common"];
        
        package = @"";
    }
    
    //"common":{"meaning":"", "explain":"<p>The edge of something is the part of it that is farthest from the center.</p>", "example":"<p>He ran to the edge of the cliff.</p>"}}
    
    NSString *strExplanation = [dictSinglePackage valueForKey:@"explain"];
    NSString *strExample = [dictSinglePackage valueForKey:@"example"];
    
    strExplanation = [strExplanation stringByReplacingOccurrencesOfString:@"&nbsp;" withString:@" "];
    strExample = [strExample stringByReplacingOccurrencesOfString:@"&nbsp;" withString:@" "];
    
    //remove html tag, use for playing speech
    NSString *plainExplanation = @"";
    NSString *plainExample = @"";
    
    if (strExplanation) {
        plainExplanation = [[Common sharedCommon] stringByRemovingHTMLTag:strExplanation];
    }
    
    if (strExample) {
        plainExample = [[Common sharedCommon] stringByRemovingHTMLTag:strExample];
    }
    
    NSString *strMeaning = @"";
    
    if ([dictSinglePackage valueForKey:@"meaning"]) {
        strMeaning = [dictSinglePackage valueForKey:@"meaning"];
        
        if (strMeaning) {
//            strMeaning = [[Common sharedCommon] stringByRemovingHTMLTag:strMeaning];
            //remove <p>, keep <br>
            strMeaning = [strMeaning stringByReplacingOccurrencesOfString:@"<p>" withString:@""];
            strMeaning = [strMeaning stringByReplacingOccurrencesOfString:@"</p>" withString:@""];
            
        } else {
            strMeaning = @"";
        }
    }
    
    NSNumber *displayMeaningFlag = [[Common sharedCommon] loadDataFromUserDefaultStandardWithKey:KEY_DISPLAYMEANING];
    
    if ([displayMeaningFlag boolValue] == NO) {
        
        strMeaning = @"";
    }
    
    NSString *strExplainIconTag = @"";
    NSString *strExampleIconTag = @"";
    NSString *strNoteTag = @"";
    
    NSNumber *speedNumberObj = [[Common sharedCommon] loadDataFromUserDefaultStandardWithKey:KEY_SPEAKING_SPEED];
    float speed = 2*[speedNumberObj floatValue];

    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 9.0) {
        speed = speed/2;
    }
    
    //create html
    
    NSString *strWordIconTag = @"<div style='float:left;width:10%%'>\n"
                                "<a onclick='playText(\"%@\", %f);'><img src='ic_speaker.png'/></a>\n"
                                "</div>\n";
    strWordIconTag = [NSString stringWithFormat:strWordIconTag, word.question, speed];
    
    if (strExplanation && strExplanation.length > 0) {
        strExplainIconTag = @"<div style=\"float:left;width:90%%; font-size:14pt;\">"
                            "   <em>%@</em> \n" //%@ will be replaced by strExplanation
                            "</div>\n"
                            "<div style=\"float:left;width:10%%\">\n "
                            "   <p><a onclick='playText(\"%@\", %f);'><img src='ic_speaker.png'/></a></p>\n"  //%@ will be replaced by strExplanation
                            "</div>\n";
        strExplainIconTag = [NSString stringWithFormat:strExplainIconTag, strExplanation, plainExplanation, speed];
    }
    
    if (strExample && strExample.length > 0) {
        strExampleIconTag = @"       <div style=\"width:90%%; font-size:12pt;\"><strong>Example: </strong></div>\n"
                            "<div style=\"float:left;width:90%%; font-size:14pt;\">"
                            "   <em>%@</em> \n" //%@ will be replaced by strExample
                            "</div>\n"
                            "<div style=\"float:left;width:10%%\">\n "
                            "   <p><a onclick='playText(\"%@\", %f);'><img src='ic_speaker.png'/></a></p>\n"  //%@ will be replaced by strExample
                            "</div>\n";
        strExampleIconTag = [NSString stringWithFormat:strExampleIconTag, strExample, plainExample, speed];
    }
    
    NSString *userNote = word.userNote;
    
    if (userNote && userNote.length > 0) {
        userNote = [userNote stringByReplacingOccurrencesOfString:@"\n" withString:@"<br>"];
        NSString *userNoteLabel = LocalizedString(@"User note");
        strNoteTag = @"<div style=\"width:100%%; font-size:12pt;\"><br><center><hr></center></div>\n"
        "<div style=\"width:100%%; font-size:12pt;\"><strong>%@: </strong></div>\n"
        "<div style=\"width:100%%; font-size:14pt;\">"
        "   <em>%@</em> \n" //%@ will be replaced by word.userNote
        "</div>\n";
        strNoteTag = [NSString stringWithFormat:strNoteTag, userNoteLabel, userNote];
    }
    
    htmlString = @"<html>\n"
    "<head>\n"
    "<meta content=\"width=device-width, initial-scale=1.0, user-scalable=yes\"\n"
    "name=\"viewport\">\n"
    "<style>\n"
        "figure {"
        "   text-align: center;"
        "   margin: auto;"
        "}"
        "figure.image img {"
        "   width: 100%% !important;"
        "   height: auto !important;"
        "}"
        "figcaption {"
        "   font-size: 10px;"
        "}"
        "a {"
        "   margin-top:10px;"
        "}"
        "hr {"
            "border: 0;"
            "border-top: 3px double #8c8c8c;"
            "text-align:center;"
        "}"

    "</style>\n"
    "<script>"

    //play the text
    "function playText(content, rate) {"
    "   var speaker = new SpeechSynthesisUtterance();"
    "   speaker.text = content;"
    "   speaker.lang = 'en-US';"
    "   speaker.rate = rate;" //0.1
    "   speaker.pitch = 1.0;"
    "   speaker.volume = 1.0;"
    "   speechSynthesis.cancel();"
    "   speechSynthesis.speak(speaker);"
    "}"
    //cancel speech
    "function cancelSpeech() {"
    "   speechSynthesis.pause();"
    "   speechSynthesis.cancel();"
    "}"
    "</script>"
    
    "</head>\n"
    "<body>\n"
    "   <div style='width:100%%'>\n"
    
    "       <div style='float:left;width:90%%;text-align: center;'>\n"
    "           <strong style='font-size:18pt;'> %@ </strong>\n"    //%@ will be replaced by word
    "       </div>\n"
    
    "       %@\n"   //%@ will be replaced by strWordIconTag
    
    "       <div style='width:90%%'>\n"
    "           <center><font size='4'> %@ </font></center>\n"  //%@ will be replaced by pronunciation
    "       </div>\n"
    
    "           <p style=\"text-align: center;\"> %@ </p>\n"  //%@ will be replaced by image link, temporary leave it blank
    
    "       <div style=\"width:100%%\"></div>\n"
    "            %@ \n"     //%@ will be replaced by strExplainIconTag

    "            %@ \n"     //%@ will be replaced by strExampleIconTag
    
    "       <div style='width:90%%'>\n"
    "           <br><br><br><br><center>%@<font size='4' color='blue'><em style='margin-left: 10px'> %@ </em></font></center>\n"    //%@ will be replaced by meaning
    "       </div>\n"
    "   </div>\n"
    
    "            %@ \n"     //%@ will be replaced by strNoteTag
    
    "   </body>"
    "</html>\n";

    htmlString = [NSString stringWithFormat:htmlString, word.question, strWordIconTag, strPronounciation, imageLink, strExplainIconTag, strExampleIconTag, package, strMeaning, strNoteTag];
    return htmlString;
    
}

//dictType: vn, en
- (NSString *)createHTMLDict:(WordObject *)wordObj dictType:(NSString *)dictType {
    NSString *htmlString = @"";
    
    htmlString = @"<html>\n"
    "<head>\n"
    "<meta content=\"width=device-width, initial-scale=1.0, user-scalable=yes\"\n"
    "name=\"viewport\">\n"
    "<style>\n"
    ".tl {\n"
    "    font-size: 14px;\n"
    "    color: #0e74af;\n"
    "    font-weight: bold;\n"
    "}"
    ".ex {\n"
    "    color: gray;\n"
    "    margin-left: 15px;\n"
    "}"
    "figure {"
    "   text-align: center;"
    "   margin: auto;"
    "}"
    "figure.image img {"
    "   width: 100%% !important;"
    "   height: auto !important;"
    "}"
    "figcaption {"
    "   font-size: 10px;"
    "}"
    "a {"
    "   margin-top:10px;"
    "}"
    "</style>\n"
    "<script>"
    "</script>"
    
    "</head>\n"
    "<body>\n"
    "   <div style='width:100%%'>\n"
    "       %@ \n"     //%@ will be replaced by l_vn or l_en
    "   </div>\n"
    "   </body>"
    "</html>\n";
    
    if ([dictType isEqualToString:@"vi"]) {
        htmlString = [NSString stringWithFormat:htmlString, wordObj.langVN];
        
    } else if ([dictType isEqualToString:@"en"]) {
        htmlString = [NSString stringWithFormat:htmlString, wordObj.langEN];
    }
    
    return htmlString;
}
@end
