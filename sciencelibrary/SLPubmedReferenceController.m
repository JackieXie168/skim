#import "SLPubmedReferenceController.h"

@implementation SLPubmedReferenceController

//datasource methods for pubmed table

-(void)awakeFromNib {
    [pubmedReferenceTable setAction:@selector(pubmedReferenceTableRowClicked:)];
    [pubmedReferenceTable setDoubleAction:@selector(openReferenceInBrowser:)];
}

-(void)pubmedReferenceTableRowClicked:(id)sender {
 
    [[self selection] setValue:[NSColor blackColor] forKey:@"referenceTextColor"];
}



- (BOOL) tableView: (NSTableView *) view
         writeRows: (NSArray *) rows
      toPasteboard: (NSPasteboard *) pboard
{
    NSLog(@"dragging");
    id object = [[self arrangedObjects] objectAtIndex: [[rows lastObject] intValue]];
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject: object];
    
    [pboard declareTypes: [NSArray arrayWithObject:@"PBtype"]
						      owner: nil];
    [pboard setData: data forType:@"PBType"];
    return YES;
}

-(void)openReferenceInBrowser:(id)sender {
    NSLog(@"double Clicked pubmed ref");
    NSString *referenceLink=[NSString stringWithFormat:@"http://www.ncbi.nlm.nih.gov/entrez/eutils/elink.fcgi?dbfrom=pubmed&id=%@&retmode=ref&cmd=prlinks",[[self selection] valueForKey:@"referencePMID"]];
    
    [[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString:referenceLink]];
}



@end
