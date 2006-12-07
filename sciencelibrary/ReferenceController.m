//
//  ReferenceController.m
//  CocoaMed
//
//  Created by kmarek on Sun Mar 31 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import "ReferenceController.h"
#import "reference.h"
#import "XMLParser.h"

@implementation ReferenceController

-(id)initWithReference:(id)referenceToShow {
    self=[super initWithWindowNibName:@"ReferenceWindow"];
    [self setCurrentReference:referenceToShow];
    [currentReference loadWholeReference];
    return self;
}

-(void)windowDidLoad {
    NSMutableString *linkXMLString;
    
    [referenceTitle setStringValue:[currentReference valueForKey:@"articleTitle"]];
    [referenceAuthors setStringValue:[currentReference valueForKey: @"articleAuthors"]];
    [referenceAbstract setStringValue:[currentReference valueForKey:@"articleAbstract"]];
    [referenceJournal setStringValue:[NSString stringWithFormat:@"%@, %@:%@, pp. %@", [currentReference valueForKey:@"articleJournal"],[currentReference valueForKey:@"articleVolume"],[currentReference valueForKey:@"articleIssue"],[currentReference valueForKey:@"articlePages"]]];

    //This should be in a separate thread that loads the linout URL.
    //The Full Text button should be dimmed until this thread is complete.
    linkXMLString=[NSString stringWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://www.ncbi.nlm.nih.gov/entrez/utils/pmlink.fcgi?db=Medline&id=%@&mode=xml&limit=1",[currentReference valueForKey:@"referencePMID"]]]];
    NSLog(@"1a");
    [currentReference setReferenceLink:[NSString stringWithFormat:@"http://www.ncbi.nlm.nih.gov%@",[XMLParser parse:linkXMLString withBeginningTag:@"<Url>" withEndingTag:@"</Url>"]]];
    //End separate thread

    }


//Instance Methods
-(IBAction) nextReference {
}

-(IBAction) prevReference {
}

-(IBAction) openReferenceButtonClicked:(id) sender {
    [self openReferenceInBrowser];
}

-(void)openReferenceInBrowser {
    [[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString:[currentReference referenceLink]]];
}

//Accessor methods

-(reference *)currentReference {
    return currentReference;
}
-(void) setCurrentReference:(reference *)aReference {
    [aReference retain];
    [currentReference release];
    currentReference=aReference;
}


    
@end
