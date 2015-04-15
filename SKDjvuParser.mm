//
//  SKDjvuParser.mm
//  DjvuParser
//
//  Created by Sylvain Bouchard on 13-06-12, based on the work of Alex Martynov 2/13/12.
//  Copyright (c) 2012 Sylvain Bouchard. All rights reserved.
//

#import "SKDjvuParser.h"
#import "SKTextArea.h"

#import "ddjvuapi.h"
#import "miniexp.h"

//#import "NSString+UUID.h"
//#import "CUCodeProfiling.h"

struct SKDjvuParserContext
{
    ddjvu_context_t *ddjvu_context;
    ddjvu_document_t *ddjvu_document;
};

@interface SKDjvuParser()

@property(nonatomic, assign) NSUInteger numberOfPages;

+ (SKDjvuParserContext *)contextWithFilePath:(NSString*)path;
- (void)loadFile;
- (bool)parseChunk:(miniexp_t)chunk returnAreas:(NSMutableArray*)areas;

@end

@implementation SKDjvuParser


#pragma mark -
#pragma mark properties

@synthesize numberOfPages = _numberOfPages;

- (id) initWithPath:(NSString*)path
{
    if (self = [super init])
    {
        filePath = [path copy];
		context = [SKDjvuParser contextWithFilePath:filePath];
		[self loadFile];
    }
    return self;
}


#pragma mark -
#pragma mark public

- (UIImage*)imageForPage:(NSUInteger)page ofSize:(CGSize)size
{
    // Check if dealing with empty document
	if(self.numberOfPages == 0)
    {
		return nil;
    }
	
    ddjvu_page_t *djvu_page = ddjvu_page_create_by_pageno(context->ddjvu_document, page);
    if(djvu_page == NULL)
    {
        NSLog(@"Can't create djvu page of number %d", page);
        return nil;
    }
    
    ddjvu_rect_t pageRect;
    pageRect.x = 0;
    pageRect.y = 0;
    pageRect.w = ddjvu_page_get_width(djvu_page);
    pageRect.h = ddjvu_page_get_height(djvu_page);
    
    unsigned int masks[3];
    masks[0] = 0xff000000;
    masks[1] = 0x00ff0000;
    masks[2] = 0x0000ff00;
    
    // Set pixel format
    ddjvu_format_t *format = ddjvu_format_create(DDJVU_FORMAT_RGBMASK32, 3, masks);
    if(format == NULL)
    {
        NSLog(@"Can't create djvu format");
        return nil;
    }
    
    // Rows in the pixel buffer are stored starting from the bottom to the top of the image
    ddjvu_format_set_row_order(format, 1);
    // y coordinates in the drawing area are oriented from top to bottom
    ddjvu_format_set_y_direction(format, 1);
	
    unsigned long rowsize = pageRect.w * 4;
	unsigned char* rgba = (unsigned char*)malloc(pageRect.w * pageRect.h * 4);
    int rs = ddjvu_page_render(djvu_page,
                               DDJVU_RENDER_COLOR,
                               &pageRect,
                               &pageRect,
                               format,
                               rowsize,
                               (char*) rgba);
    if(rs == 0)
    {
        // No image could be computed at this point, and nothing was written into
        // the buffer.
        return nil;
    }
	
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef bitmapContext = CGBitmapContextCreate(rgba,
                                                       pageRect.w,
                                                       pageRect.h,
                                                       8, // bitsPerComponent
													   4 * pageRect.w, // bytesPerRow
                                                       colorSpace,
                                                       kCGImageAlphaNoneSkipFirst
                                                       );
    CFRelease(colorSpace);
	
	ddjvu_page_release(djvu_page);
    
    CGImageRef cgImage = CGBitmapContextCreateImage(bitmapContext);
    return [UIImage imageWithCGImage:cgImage];
}

- (bool)textForPage:(NSUInteger)page returnAreas:(NSMutableArray*)areas
{
    // Make sure output array is non-null and empty
    if(areas != nil)
    {
        [areas removeAllObjects];
    }
    else
    {
        return false;
    }
    
    miniexp_t chunk;
    while((chunk = ddjvu_document_get_pagetext(context->ddjvu_document, page, 0)) == miniexp_dummy)
    {
        NSLog(@"Text extraction in progress...");
    }
    
    if(miniexp_nil == chunk)
        return false;
    
//    miniexp_pprint(chunk, 72);

    return [self parseChunk:chunk returnAreas:areas];
}


#pragma mark -
#pragma mark private

//TODO: error handling
+ (SKDjvuParserContext *)contextWithFilePath:(NSString*)path
{
    SKDjvuParserContext* result = (SKDjvuParserContext*)calloc(1, sizeof(SKDjvuParserContext));
    
    NSString *uniqueAppID = [NSString stringWithFormat:@"DjvuViewer_%@", @"00"];
    //ddjvu_document_create_by_filename_utf8
    result->ddjvu_context = ddjvu_context_create([uniqueAppID UTF8String]);
    result->ddjvu_document = ddjvu_document_create_by_filename(result->ddjvu_context,
                                                                [path UTF8String],
                                                                FALSE);
	return result;
}

- (void)loadFile
{
	if (context->ddjvu_document == NULL)
		return;
	int np = ddjvu_document_get_pagenum(context->ddjvu_document);
	
	if (np < 0)
		np = 0;
	
	self.numberOfPages = (NSUInteger)np;
}

- (bool)parseChunk:(miniexp_t)chunk returnAreas:(NSMutableArray*)areas
{
    // Create text area object representation
    SKTextArea* textArea = [[SKTextArea alloc] init];
    
    // Extract chunk type
    miniexp_t type = miniexp_car(chunk);
    if(miniexp_symbolp(type))
    {
        textArea.type = [SKTextArea toAreaTypeFromCString:miniexp_to_name(type)];
    }
    
    // Parse chunk metrics
    chunk = miniexp_cdr(chunk);
    if(!miniexp_numberp(miniexp_car(chunk))) return NULL;
    int x0 = miniexp_to_int(miniexp_car(chunk)); chunk = miniexp_cdr(chunk);
    if(!miniexp_numberp(miniexp_car(chunk))) return NULL;
    int y0 = miniexp_to_int(miniexp_car(chunk)); chunk = miniexp_cdr(chunk);
    if(!miniexp_numberp(miniexp_car(chunk))) return NULL;
    int x1 = miniexp_to_int(miniexp_car(chunk)); chunk = miniexp_cdr(chunk);
    if(!miniexp_numberp(miniexp_car(chunk))) return NULL;
    int y1 = miniexp_to_int(miniexp_car(chunk)); chunk = miniexp_cdr(chunk);
    
    CGRect bounds = CGRectMake(x0, y0, x1 - x0, y1 - y0);
    textArea.boundingRect = bounds;
    
//    miniexp_pprint(chunk, 72);
    
    while(chunk != NULL)
    {
        miniexp_t subChunk = miniexp_car(chunk);
        //miniexp_pprint(subChunk, 72);
        
        // Determine if there are child elements -- if so, parse them recursively
        if(miniexp_stringp(subChunk))
        {
            // No child element, process text element
            const char *cstr = miniexp_to_str(subChunk);
            NSString *content = [NSString stringWithCString:cstr encoding:NSUTF8StringEncoding];
            textArea.textContent = content;
        }
        else
        {
            // Child elements present, process them...
            [self parseChunk:subChunk returnAreas:areas];
        }
        chunk = miniexp_cdr(chunk);
    }
    
    // Add extracted element to output
    [areas addObject:textArea];
    
    return true;
}

@end
