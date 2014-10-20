//
//  DGSpreadSheetExport.h
//  DGSpreadSheetExport
//
//  CSV or XMLSS (XML Spreadsheet) generation library
//
//  Created by Daniel Cohen Gindi (danielgindi@gmail.com)
//
//  https://github.com/danielgindi/DGSpreadSheetExport
//
//  The MIT License (MIT)
//  
//  Copyright (c) 2014 Daniel Cohen Gindi (danielgindi@gmail.com)
//  
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//  
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//  
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE. 
//  

#import "DGSpreadSheetExport.h"

@interface DGSpreadSheetExport ()
- (NSString *)prepareString:(NSString *)string;
- (void)write:(NSString *)output;
- (void)seekToFirstRow;
- (void)seekToEnd;
- (void)keepRecordOfFirstRowPosition;
- (void)writeStyle:(int)idxStyle;
- (void)beginWorksheet;
- (void)endWorksheet;
- (void)endRow;
@end

@implementation DGSpreadSheetExport
{
    NSFileHandle *_fileHandle;
    NSStringEncoding _fileEncoding;
    NSMutableString *_outputString;
    NSMutableString *_outputTempString;
    BOOL _isXml;
    NSMutableArray *_columnsArray;
    NSMutableArray *_stylesArray;
    BOOL _startWorksheet;
    BOOL _endWorksheet;
    BOOL _endRow;
    NSUInteger _firstRowPosStr;
    unsigned long long _firstRowPosFile;
    BOOL _insertAtBegin;
}

@synthesize isXml = _isXml, fileExtension, fileContentType;

- (id)init
{
    if ((self = [super init]))
    {
        _isXml = YES;
        _fileEncoding = NSUTF8StringEncoding;
        _columnsArray = [[NSMutableArray alloc] init];
        _stylesArray = [[NSMutableArray alloc] init];
        _startWorksheet = NO;
        _endWorksheet = NO;
        _endRow = NO;
        _insertAtBegin = NO;
    }
    return self;
}

- (id)initAsXml:(bool)isXml intoFileHandle:(NSFileHandle *)fileHandle withEncoding:(NSStringEncoding)encoding
{
    if ((self = [self init]))
    {
        _isXml = isXml;
        _fileEncoding = encoding;
        if (fileHandle)
        {
            _fileHandle = fileHandle;
#ifdef DEBUG // In debug mode do output to string anyway, for description
            _outputString = [[NSMutableString alloc] init];
#endif
        }
        else
        {
            _outputString = [[NSMutableString alloc] init];
        }
    }
    return self;
}

- (id)initAsXml:(bool)isXml intoFileHandle:(NSFileHandle *)fileHandle
{
    if ((self = [self initAsXml:isXml intoFileHandle:fileHandle withEncoding:NSUTF8StringEncoding]))
    {
    }
    return self;
}

- (id)initAsXml:(bool)isXml
{
    if ((self = [self initAsXml:isXml intoFileHandle:nil withEncoding:NSUTF8StringEncoding]))
    {
    }
    return self;
}

- (NSString *) getFileExtension
{
    if (_isXml) return @"xml";
    else return @"csv";
}

- (NSString *) getFileContentType
{
    if (_isXml) return @"text/xml";
    else return @"application/vnd.ms-excel";
}

- (NSString *)prepareString:(NSString *)string
{
    if (_isXml)
    {
        string = [string stringByReplacingOccurrencesOfString:@"&" withString:@"&amp;"];
        string = [string stringByReplacingOccurrencesOfString:@"<" withString:@"&lt;"];
        string = [string stringByReplacingOccurrencesOfString:@">" withString:@"&gt;"];
        string = [string stringByReplacingOccurrencesOfString:@"\"" withString:@"&quot;"];
        string = [string stringByReplacingOccurrencesOfString:@"'" withString:@"&apos;"];
        string = [string stringByReplacingOccurrencesOfString:@"\r" withString:@"&#xD;"];
        string = [string stringByReplacingOccurrencesOfString:@"\n" withString:@"&#xA;"];
    }
    else
    {
        string = [string stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
        string = [string stringByReplacingOccurrencesOfString:@"\r" withString:@" "];
        string = [string stringByReplacingOccurrencesOfString:@"\"" withString:@"\"\""];
    }
    return string;
}

- (void)write:(NSString *)output
{
    if (_fileHandle)
    {
        [_fileHandle writeData:[output dataUsingEncoding:_fileEncoding]];
    }
#ifndef DEBUG // In debug mode do output to string anyway, for description
    else
    {
#endif
        if (_insertAtBegin) [_outputTempString appendString:output];
        else [_outputString appendString:output];
#ifndef DEBUG
    }
#endif
}

- (void)seekToFirstRow
{
    if (_fileHandle)
    {
        // this overwrites existing data, so do not do this!
        //[_fileHandle seekToFileOffset:_firstRowPosFile];
    }
#ifndef DEBUG // In debug mode do output to string anyway, for description
    else
    {
#endif
        [self seekToEnd];
        _outputTempString = [[NSMutableString alloc] init];
#ifndef DEBUG
    }
#endif
    _insertAtBegin  = true;
}

- (void)seekToEnd
{
    if (!_insertAtBegin) return;
    if (_fileHandle)
    {
        //[_fileHandle seekToEndOfFile];
    }
#ifndef DEBUG // In debug mode do output to string anyway, for description
    else
    {
#endif
        if (_outputTempString)
        {
            [_outputString insertString:_outputTempString atIndex:_firstRowPosStr];
            _outputTempString = nil;
        }
#ifndef DEBUG
    }
#endif
    _insertAtBegin  = false;
}

- (void)keepRecordOfFirstRowPosition
{
    [self seekToEnd];
    if (_fileHandle)
    {
        _firstRowPosFile  = _fileHandle.offsetInFile;
    }
#ifndef DEBUG // In debug mode do output to string anyway, for description
    else
    {
#endif
        _firstRowPosStr  = _outputString.length;
#ifndef DEBUG
    }
#endif
}

- (NSString *)cssStringForUIColor:(UIColor *)color
{
	CGFloat *oldComponents = (CGFloat *)CGColorGetComponents(color.CGColor);
	CGFloat r,g,b/*,a*/;
    // Should we also account for Alpha colors here? We need to test if apps like Excel supports it.
    
	NSInteger numComponents = CGColorGetNumberOfComponents(color.CGColor);
    
	switch (numComponents)
	{
		case 2:
		{
			//grayscale
			r = oldComponents[0];
			g = oldComponents[0];
			b = oldComponents[0];
			//a = oldComponents[1];
			break;
		}
		case 4:
		{
			//RGBA
			r = oldComponents[0];
			g = oldComponents[1];
			b = oldComponents[2];
			//a = oldComponents[3];
			break;
		}
        default:
            return nil;
	}
    
    
	r = MIN(MAX(r, 0.0f), 1.0f);
	g = MIN(MAX(g, 0.0f), 1.0f);
	b = MIN(MAX(b, 0.0f), 1.0f);
    
	UInt32 rgb = (((int)roundf(r * 255)) << 16)
                | (((int)roundf(g * 255)) << 8)
                | (((int)roundf(b * 255)));

    return [NSString stringWithFormat:@"#%0.6X", (unsigned int)rgb];
}

- (void)writeStyle:(int)idxStyle
{
    [self write:[NSString stringWithFormat:@"<ss:Style ss:ID=\"s%d\">", idxStyle + 21]];
    
    DGSpreadSheetExportStyle *style = [_stylesArray objectAtIndex:idxStyle];
    
    if (style.alignment)
    {
        [self write:@"<ss:Alignment"]; // Opening tag
        
        NSString *horizontal = nil;
        switch (style.alignment.horizontal)
        {
            default:
            case DGSpreadSheetExportAlignmentHorizontalAutomatic: // Default
                break;
            case DGSpreadSheetExportAlignmentHorizontalLeft:
                horizontal = @"Left";
                break;
            case DGSpreadSheetExportAlignmentHorizontalCenter:
                horizontal = @"Center";
                break;
            case DGSpreadSheetExportAlignmentHorizontalRight:
                horizontal = @"Right";
                break;
            case DGSpreadSheetExportAlignmentHorizontalFill:
                horizontal = @"Fill";
                break;
            case DGSpreadSheetExportAlignmentHorizontalJustify:
                horizontal = @"Justify";
                break;
            case DGSpreadSheetExportAlignmentHorizontalCenterAcrossSelection:
                horizontal = @"CenterAcrossSelection";
                break;
            case DGSpreadSheetExportAlignmentHorizontalDistributed:
                horizontal = @"Distributed";
                break;
            case DGSpreadSheetExportAlignmentHorizontalJustifyDistributed:
                horizontal = @"JustifyDistributed";
                break;
        }
        if (horizontal)
        {
            [self write:[NSString stringWithFormat:@" ss:Horizontal=\"%@\"", horizontal]];
        }
        
        if (style.alignment.indent > 0) // 0 is default
        {
            [self write:[NSString stringWithFormat:@" ss:Indent=\"%lu\"", (unsigned long)style.alignment.indent]];
        }
        
        NSString *readingOrder = nil;
        switch (style.alignment.readingOrder)
        {
            default:
            case DGSpreadSheetExportAlignmentReadingOrderContext: // Default
                break;
            case DGSpreadSheetExportAlignmentReadingOrderRightToLeft:
                readingOrder = @"RightToLeft";
                break;
            case DGSpreadSheetExportAlignmentReadingOrderLeftToRight:
                readingOrder = @"LeftToRight";
                break;
        }
        if (readingOrder)
        {
            [self write:[NSString stringWithFormat:@" ss:ReadingOrder=\"%@\"", readingOrder]];
        }
        
        if (style.alignment.rotate != 0.0) // 0 is default
        {
            [self write:[NSString stringWithFormat:@" ss:Rotate=\"%f\"", style.alignment.rotate]];
        }
        
        if (style.alignment.shrinkToFit) // FALSE is default
        {
            [self write:[NSString stringWithFormat:@" ss:ShrinkToFit=\"1\""]];
        }
        
        NSString *vertical = nil;
        switch (style.alignment.vertical)
        {
            default:
            case DGSpreadSheetExportAlignmentVerticalAutomatic: // Default
                break;
            case DGSpreadSheetExportAlignmentVerticalTop:
                vertical = @"Top";
                break;
            case DGSpreadSheetExportAlignmentVerticalBottom:
                vertical = @"Bottom";
                break;
            case DGSpreadSheetExportAlignmentVerticalCenter:
                vertical = @"Center";
                break;
            case DGSpreadSheetExportAlignmentVerticalJustify:
                vertical = @"Justify";
                break;
            case DGSpreadSheetExportAlignmentVerticalDistributed:
                vertical = @"Distributed";
                break;
            case DGSpreadSheetExportAlignmentVerticalJustifyDistributed:
                vertical = @"JustifyDistributed";
                break;
        }
        if (vertical)
        {
            [self write:[NSString stringWithFormat:@" ss:Vertical=\"%@\"", vertical]];
        }
        
        if (style.alignment.verticalText) // FALSE is default
        {
            [self write:[NSString stringWithFormat:@" ss:VerticalText=\"1\""]];
        }
        
        if (style.alignment.wrapText) // FALSE is default
        {
            [self write:[NSString stringWithFormat:@" ss:WrapText=\"1\""]];
        }
        
        [self write:@"/>\n"]; // Closing tag
    }
    
    if (style.numberFormat.length)
    {
        [self write:[NSString stringWithFormat:@"<ss:NumberFormat ss:Format=\"%@\"/>", style.numberFormat]];
    }
    
    if (style.borders.count)
    {
        [self write:@"<ss:Borders>"]; // Opening tag
        
        for (DGSpreadSheetExportBorder *border in style.borders)
        {
            [self write:@"<ss:Border"]; // Opening tag
            
            NSString *position = nil;
            switch (border.position)
            {
                default:
                case DGSpreadSheetExportBorderPositionLeft:
                    position = @"Left";
                    break;
                case DGSpreadSheetExportBorderPositionTop:
                    position = @"Top";
                    break;
                case DGSpreadSheetExportBorderPositionRight:
                    position = @"Right";
                    break;
                case DGSpreadSheetExportBorderPositionBottom:
                    position = @"Bottom";
                    break;
                case DGSpreadSheetExportBorderPositionDiagonalLeft:
                    position = @"DiagonalLeft";
                    break;
                case DGSpreadSheetExportBorderPositionDiagonalRight:
                    position = @"DiagonalRight";
                    break;
            }
            [self write:[NSString stringWithFormat:@" ss:Position=\"%@\"", position]]; // Required
            
            if (border.color && border.color != [UIColor clearColor])
            {
                [self write:[NSString stringWithFormat:@" ss:Color=\"%@\"", [self cssStringForUIColor:border.color]]];            
            }
            
            NSString *lineStyle = nil;
            switch (border.lineStyle)
            {
                default:
                case DGSpreadSheetExportBorderLineStyleNone: // Default
                    break;
                case DGSpreadSheetExportBorderLineStyleContinuous:
                    lineStyle = @"Continuous";
                    break;
                case DGSpreadSheetExportBorderLineStyleDash:
                    lineStyle = @"Dash";
                    break;
                case DGSpreadSheetExportBorderLineStyleDot:
                    lineStyle = @"Dot";
                    break;
                case DGSpreadSheetExportBorderLineStyleDashDot:
                    lineStyle = @"DashDot";
                    break;
                case DGSpreadSheetExportBorderLineStyleDashDotDot:
                    lineStyle = @"DashDotDot";
                    break;
                case DGSpreadSheetExportBorderLineStyleSlantDashDot:
                    lineStyle = @"SlantDashDot";
                    break;
                case DGSpreadSheetExportBorderLineStyleDouble:
                    lineStyle = @"Double";
                    break;
            }
            if (lineStyle)
            {
                [self write:[NSString stringWithFormat:@" ss:LineStyle=\"%@\"", lineStyle]];
            }
            
            if (border.weight > 0.0) // 0 is default
            {
                [self write:[NSString stringWithFormat:@" ss:Weight=\"%f\"", border.weight]];
            }
            
            [self write:@"/>\n"]; // Closing tag
        }
        
        [self write:@"</ss:Borders>\n"]; // Closing tag
    }
    
    if (style.interior)
    {
        [self write:@"<ss:Interior"]; // Opening tag
        
        if (style.interior.color && style.interior.color != [UIColor clearColor])
        {
            [self write:[NSString stringWithFormat:@" ss:Color=\"%@\"", [self cssStringForUIColor:style.interior.color]]];            
        }
        
        NSString *pattern = nil;
        switch (style.interior.pattern)
        {
            default:
            case DGSpreadSheetExportInteriorPatternNone: // Default
                break;
            case DGSpreadSheetExportInteriorPatternSolid:
                pattern = @"Solid";
                break;
            case DGSpreadSheetExportInteriorPatternGray75:
                pattern = @"Gray75";
                break;
            case DGSpreadSheetExportInteriorPatternGray50:
                pattern = @"Gray50";
                break;
            case DGSpreadSheetExportInteriorPatternGray25:
                pattern = @"Gray25";
                break;
            case DGSpreadSheetExportInteriorPatternGray125:
                pattern = @"Gray125";
                break;
            case DGSpreadSheetExportInteriorPatternGray0625:
                pattern = @"Gray0625";
                break;
            case DGSpreadSheetExportInteriorPatternHorzStripe:
                pattern = @"HorzStripe";
                break;
            case DGSpreadSheetExportInteriorPatternVertStripe:
                pattern = @"VertStripe";
                break;
            case DGSpreadSheetExportInteriorPatternReverseDiagStripe:
                pattern = @"ReverseDiagStripe";
                break;
            case DGSpreadSheetExportInteriorPatternDiagCross:
                pattern = @"DiagCross";
                break;
            case DGSpreadSheetExportInteriorPatternThickDiagCross:
                pattern = @"ThickDiagCross";
                break;
            case DGSpreadSheetExportInteriorPatternThinHorzStripe:
                pattern = @"ThinHorzStripe";
                break;
            case DGSpreadSheetExportInteriorPatternThinVertStripe:
                pattern = @"ThinVertStripe";
                break;
            case DGSpreadSheetExportInteriorPatternThinReverseDiagStripe:
                pattern = @"ThinReverseDiagStripe";
                break;
            case DGSpreadSheetExportInteriorPatternThinDiagStripe:
                pattern = @"ThinDiagStripe";
                break;
            case DGSpreadSheetExportInteriorPatternThinHorzCross:
                pattern = @"ThinHorzCross";
                break;
            case DGSpreadSheetExportInteriorPatternThinDiagCross:
                pattern = @"ThinDiagCross";
                break;
        }
        if (pattern)
        {
            [self write:[NSString stringWithFormat:@" ss:Pattern=\"%@\"", pattern]];
        }
        
        if (style.interior.patternColor && style.interior.patternColor != [UIColor clearColor])
        {
            [self write:[NSString stringWithFormat:@" ss:PatternColor=\"%@\"", [self cssStringForUIColor:style.interior.patternColor]]];            
        }
        
        [self write:@"/>\n"]; // Closing tag
    }
    
    if (style.font)
    {
        [self write:@"<ss:Font"]; // Opening tag
        
        if (style.font.bold) // FALSE is default
        {
            [self write:[NSString stringWithFormat:@" ss:Bold=\"1\""]];
        }
        
        if (style.font.color && style.font.color != [UIColor clearColor])
        {
            [self write:[NSString stringWithFormat:@" ss:Color=\"%@\"", [self cssStringForUIColor:style.font.color]]];            
        }
        
        if (style.font.fontName)
        {
            [self write:[NSString stringWithFormat:@" ss:FontName=\"%@\"", style.font.fontName]];
        }
        
        if (style.font.italic) // FALSE is default
        {
            [self write:[NSString stringWithFormat:@" ss:Italic=\"1\""]];
        }
        
        if (style.font.outline) // FALSE is default
        {
            [self write:[NSString stringWithFormat:@" ss:Outline=\"1\""]];
        }
        
        if (style.font.shadow) // FALSE is default
        {
            [self write:[NSString stringWithFormat:@" ss:Shadow=\"1\""]];
        }
        
        if (style.font.size != 10.0) // 10 is default
        {
            [self write:[NSString stringWithFormat:@" ss:Size=\"%f\"", style.font.size]];
        }
        
        if (style.font.strikeThrough) // FALSE is default
        {
            [self write:[NSString stringWithFormat:@" ss:StrikeThrough=\"1\""]];
        }
        
        NSString *underline = nil;
        switch (style.font.underline)
        {
            default:
            case DGSpreadSheetExportFontUnderlineNone: // Default
                break;
            case DGSpreadSheetExportFontUnderlineSingle:
                underline = @"Single";
                break;
            case DGSpreadSheetExportFontUnderlineDouble:
                underline = @"Double";
                break;
            case DGSpreadSheetExportFontUnderlineSingleAccounting:
                underline = @"SingleAccounting";
                break;
            case DGSpreadSheetExportFontUnderlineDoubleAccounting:
                underline = @"DoubleAccounting";
                break;
        }
        if (underline)
        {
            [self write:[NSString stringWithFormat:@" ss:Underline=\"%@\"", underline]];
        }
        
        NSString *verticalAlign = nil;
        switch (style.font.verticalAlign)
        {
            default:
            case DGSpreadSheetExportFontVerticalAlignNone: // Default
                break;
            case DGSpreadSheetExportFontVerticalAlignSubscript:
                verticalAlign = @"Subscript";
                break;
            case DGSpreadSheetExportFontVerticalAlignSuperscript:
                verticalAlign = @"Superscript";
                break;
        }
        if (verticalAlign)
        {
            [self write:[NSString stringWithFormat:@" ss:VerticalAlign=\"%@\"", verticalAlign]];
        }
        
        if (style.font.charSet > 0) // 0 is default
        {
            [self write:[NSString stringWithFormat:@" ss:CharSet=\"%lu\"", (unsigned long)style.font.charSet]];
        }
        
        NSString *family = nil;
        switch (style.font.family)
        {
            default:
            case DGSpreadSheetExportFontFamilyAutomatic: // Default
                break;
            case DGSpreadSheetExportFontFamilyDecorative:
                family = @"Decorative";
                break;
            case DGSpreadSheetExportFontFamilyModern:
                family = @"Modern";
                break;
            case DGSpreadSheetExportFontFamilyRoman:
                family = @"Roman";
                break;
            case DGSpreadSheetExportFontFamilyScript:
                family = @"Script";
                break;
            case DGSpreadSheetExportFontFamilySwiss:
                family = @"Swiss";
                break;
        }
        if (family)
        {
            [self write:[NSString stringWithFormat:@" ss:Family=\"%@\"", family]];
        }
        
        [self write:@"/>\n"]; // Closing tag
    }
    
    [self write:@"</ss:Style>\n"];
}

- (void)beginFile
{
    if(_fileHandle) // Then write Byte-Order-Mark
    {
        switch (_fileEncoding)
        {
            case NSUTF8StringEncoding:
            {
                char bom[3]= {0xEF,0xBB,0xBF};
                [_fileHandle writeData:[NSMutableData dataWithBytes:bom length:3]];
                break;
            }
            case NSUTF16StringEncoding:
            {
                char bom[2]= {0xFF, 0xFE};
                [_fileHandle writeData:[NSMutableData dataWithBytes:bom length:2]];
                break;
            }
        }
    }
    
    if (_isXml)
    {
        [self write:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"];
        [self write:@"<?mso-application progid=\"Excel.Sheet\"?>\n"];
        [self write:@"<Workbook xmlns=\"urn:schemas-microsoft-com:office:spreadsheet\"\n"];
        [self write:@" xmlns:o=\"urn:schemas-microsoft-com:office:office\"\n"];
        [self write:@" xmlns:x=\"urn:schemas-microsoft-com:office:excel\"\n"];
        [self write:@" xmlns:ss=\"urn:schemas-microsoft-com:office:spreadsheet\">\n"];
        
        [self write:@" <Styles>\n"];
        [self write:@"  <Style ss:ID=\"Default\" ss:Name=\"Normal\">\n"];
        [self write:@"   <Alignment ss:Vertical=\"Bottom\"/>\n"];
        [self write:@"  </Style>\n"];
        
        for (int i = 0; i < _stylesArray.count; i++)
        {
            [self writeStyle:i];
        }
        [self write:@" </Styles>\n"];
    }
    else
    {
    }
    [self keepRecordOfFirstRowPosition];
}

- (void)endFile
{
    [self endWorksheet];
    if (_isXml)
    {
        [self write:@"</Workbook>\n"];
    }
}

- (void)beginWorksheet
{
    if (_isXml && _startWorksheet)
    {
        [self write:[NSString stringWithFormat:@"  <Table ss:ExpandedColumnCount=\"%lu\">\n", (unsigned long)_columnsArray.count]];
        for (NSString *Column in _columnsArray)
        {
            if (Column.length == 0)
            {
                [self write:@"   <Column ss:AutoFitWidth=\"1\"/>\n"];
            }
            else
            {
                [self write:[NSString stringWithFormat:@"   <Column ss:Width=\"%@\"/>\n", Column]];
            }
        }
        _startWorksheet = NO;
    }
}

- (void)endWorksheet
{
    if (_endWorksheet)
    {
        [self endRow];
        if (_isXml)
        {
            if (!_startWorksheet) [self write:@"  </Table>\n"];
            [self write:@" </Worksheet>\n"];
            _startWorksheet = NO;
        }
        else
        { //
        }
        _endWorksheet = NO;
    }
    [_columnsArray removeAllObjects];
}

- (void)endRow
{
    if (!_endRow) return;
    if (_isXml)
    {
        [self write:@"   </Row>\n"];
    }
    else
    {
        [self write:@"\n"];
    }
    if (_insertAtBegin)
    {
        [self seekToEnd];
    }
    _endRow = NO;
}

- (void)setCellStringValue:(NSString *)string
{
    [self setCellStringValue:string withStyleIndex:-1 andFormatValueUsingStyle:NO mergeAcross:0 mergeDown:0];
}
- (void)setCellStringValue:(NSString *)string mergeAcross:(NSUInteger)mergeAcross mergeDown:(NSUInteger)mergeDown
{
    [self setCellStringValue:string withStyleIndex:-1 andFormatValueUsingStyle:NO mergeAcross:mergeAcross mergeDown:mergeDown];
}
- (void)setCellStringValue:(NSString *)string withStyleIndex:(int)idxStyle andFormatValueUsingStyle:(BOOL)formatFromStyle
{
    [self setCellStringValue:string withStyleIndex:idxStyle andFormatValueUsingStyle:formatFromStyle mergeAcross:0 mergeDown:0];
}
- (void)setCellStringValue:(NSString *)string withStyleIndex:(int)idxStyle andFormatValueUsingStyle:(BOOL)formatFromStyle mergeAcross:(NSUInteger)mergeAcross mergeDown:(NSUInteger)mergeDown
{
    if (_isXml)
    {
        NSString *merge = (mergeAcross == 0 && mergeDown == 0) ? @"" : ((mergeAcross != 0 && mergeDown != 0) ? [NSString stringWithFormat:@" ss:MergeAcross=\"%lu\" ss:MergeDown=\"%lu\"", (unsigned long)mergeAcross, (unsigned long)mergeDown] : ((mergeAcross != 0) ? [NSString stringWithFormat:@" ss:MergeAcross=\"%lu\"", (unsigned long)mergeAcross] : [NSString stringWithFormat:@" ss:MergeDown=\"%lu\"", (unsigned long)mergeDown]));
        if (idxStyle != -1)
        {
            if (formatFromStyle)
            {
                DGSpreadSheetExportStyle *style = [_stylesArray objectAtIndex:idxStyle];
                if ((style.numberFormat && ([style.numberFormat isEqualToString:kDGSpreadSheetExportNumberFormatScientific] || [style.numberFormat isEqualToString:kDGSpreadSheetExportNumberFormatFixed] || [style.numberFormat isEqualToString:kDGSpreadSheetExportNumberFormatStandard] || [style.numberFormat isEqualToString:kDGSpreadSheetExportNumberFormat0] || [style.numberFormat isEqualToString:kDGSpreadSheetExportNumberFormat0_00])))
                {
                    [self write:[NSString stringWithFormat:@"    <Cell ss:StyleID=\"s%d\"%@><Data ss:Type=\"Number\">%@</Data></Cell>\n", idxStyle + 21, merge, [self prepareString:string]]];
                }
                else
                {
                    [self write:[NSString stringWithFormat:@"    <Cell ss:StyleID=\"s%d\"%@><Data ss:Type=\"String\">%@</Data></Cell>\n", idxStyle + 21, merge, [self prepareString:string]]];
                }
            }
            else
            {
                [self write:[NSString stringWithFormat:@"    <Cell ss:StyleID=\"s%d\"%@><Data ss:Type=\"String\">%@</Data></Cell>\n", idxStyle + 21, merge, [self prepareString:string]]];
            }
        }
        else
            [self write:[NSString stringWithFormat:@"    <Cell%@><Data ss:Type=\"String\">%@</Data></Cell>\n", merge, [self prepareString:string]]];
    }
    else
    {
        [self write:[NSString stringWithFormat:@"\"%@\",", [self prepareString:string]]];
    }
}

- (void)beginRow
{
    [self beginRowWithStyleIndex:-1 andHeight:0];
}
- (void)beginRowAtBeginningOfFile:(BOOL)beginning
{
    [self beginRowAtBeginningOfFile:beginning withStyleIndex:-1 andHeight:0];
}
- (void)beginRowWithStyleIndex:(int)idxStyle
{
    [self beginRowWithStyleIndex:idxStyle andHeight:0];
}
- (void)beginRowAtBeginningOfFile:(BOOL)beginning withStyleIndex:(int)idxStyle
{
    [self beginRowAtBeginningOfFile:beginning withStyleIndex:idxStyle andHeight:0];
}
- (void)beginRowAtBeginningOfFile:(BOOL)beginning withStyleIndex:(int)idxStyle andHeight:(float)height
{
    if (beginning)
    {
        [self endRow];
    }
    if (!_endWorksheet)
    {
        [self newWorksheetNamed:@"New Sheet"];
    }
    _insertAtBegin  = beginning;
    if (_insertAtBegin)
    {
        [self seekToFirstRow];
    }
    [self beginRowWithStyleIndex:idxStyle andHeight:height];
}

- (void)beginRowWithStyleIndex:(int)idxStyle andHeight:(float)height
{
    if (!_endWorksheet) [self newWorksheetNamed:@"New Sheet"];
    
    if (_isXml)
    {
        [self beginWorksheet];
        [self endRow];
        
        [self write:@"   <Row"];
        if (idxStyle >= 0)
            [self write:[NSString stringWithFormat:@" ss:StyleID=\"s%d\"", idxStyle + 21]];
        if (height != 0)
            [self write:[NSString stringWithFormat:@" ss:Height=\"%0.2f\"", height]];
        [self write:@">\n"];
    }
    else
    {
        [self endRow];
    }
    
    _endRow = YES;
}

- (int)addStyle:(DGSpreadSheetExportStyle *)style
{
    [_stylesArray addObject:style];
    return (int)_stylesArray.count - 1;
}

- (void)newWorksheetNamed:(NSString *)name
{
    BOOL addEmptyRow = _endWorksheet;
    
    [self endWorksheet];
    _endWorksheet = YES;
    if (_isXml)
    {
        [self write:[NSString stringWithFormat:@" <Worksheet ss:Name=\"%@\">\n", [self prepareString:name]]];
        _startWorksheet = YES;
    }
    else
    {
        if (addEmptyRow) [self beginRow];
        if (name)
        {
            [self beginRow];
            [self setCellStringValue:name];
            [self beginRow];
        }
    }
    [self keepRecordOfFirstRowPosition];
}

- (void)addColumn
{
    [self addColumnWithWidthOf:0];
}
- (void)addColumnWithWidthOf:(float)width
{
    NSString *column;
    if (width != 0)
        column = [NSString stringWithFormat:@"%0.2f", width];
    else
        column = @"";
    [_columnsArray addObject:column];
}

- (void)setCellIntValue:(int)data
{
    [self setCellIntValue:data withStyleIndex:-1 mergeAcross:0 mergeDown:0];
}
- (void)setCellIntValue:(int)data mergeAcross:(NSUInteger)mergeAcross mergeDown:(NSUInteger)mergeDown
{
    [self setCellIntValue:data withStyleIndex:-1 mergeAcross:mergeAcross mergeDown:mergeDown];
}
- (void)setCellIntValue:(int)data withStyleIndex:(int)idxStyle
{
    [self setCellIntValue:data withStyleIndex:idxStyle mergeAcross:0 mergeDown:0];
}
- (void)setCellIntValue:(int)data withStyleIndex:(int)idxStyle mergeAcross:(NSUInteger)mergeAcross mergeDown:(NSUInteger)mergeDown
{
    if (_isXml)
    {
        NSString *merge = (mergeAcross == 0 && mergeDown == 0) ? @"" : ((mergeAcross != 0 && mergeDown != 0) ? [NSString stringWithFormat:@" ss:MergeAcross=\"%lu\" ss:MergeDown=\"%lu\"", (unsigned long)mergeAcross, (unsigned long)mergeDown] : ((mergeAcross != 0) ? [NSString stringWithFormat:@" ss:MergeAcross=\"%lu\"", (unsigned long)mergeAcross] : [NSString stringWithFormat:@" ss:MergeDown=\"%lu\"", (unsigned long)mergeDown]));
        if (idxStyle != -1)
            [self write:[NSString stringWithFormat:@"    <Cell ss:StyleID=\"s%d\"%@><Data ss:Type=\"Number\">%i</Data></Cell>\n", idxStyle + 21, merge, data]];
        else
            [self write:[NSString stringWithFormat:@"    <Cell%@><Data ss:Type=\"Number\">%i</Data></Cell>\n", merge, data]];
    }
    else
    {
        [self write:[NSString stringWithFormat:@"%i,", data]];
    }
}

- (void)setCellInt64Value:(long long int)data
{ 
    [self setCellInt64Value:data withStyleIndex:-1 mergeAcross:0 mergeDown:0]; 
}
- (void)setCellInt64Value:(long long int)data mergeAcross:(NSUInteger)mergeAcross mergeDown:(NSUInteger)mergeDown
{
    [self setCellInt64Value:data withStyleIndex:-1 mergeAcross:mergeAcross mergeDown:mergeDown];
}
- (void)setCellInt64Value:(long long int)data withStyleIndex:(int)idxStyle
{
    [self setCellInt64Value:data withStyleIndex:idxStyle mergeAcross:0 mergeDown:0];
}
- (void)setCellInt64Value:(long long int)data withStyleIndex:(int)idxStyle mergeAcross:(NSUInteger)mergeAcross mergeDown:(NSUInteger)mergeDown
{
    if (_isXml)
    {
        NSString *merge = (mergeAcross == 0 && mergeDown == 0) ? @"" : ((mergeAcross != 0 && mergeDown != 0) ? [NSString stringWithFormat:@" ss:MergeAcross=\"%lu\" ss:MergeDown=\"%lu\"", (unsigned long)mergeAcross, (unsigned long)mergeDown] : ((mergeAcross != 0) ? [NSString stringWithFormat:@" ss:MergeAcross=\"%lu\"", (unsigned long)mergeAcross] : [NSString stringWithFormat:@" ss:MergeDown=\"%lu\"", (unsigned long)mergeDown]));
        if (idxStyle != -1)
            [self write:[NSString stringWithFormat:@"    <Cell ss:StyleID=\"s%d\"%@><Data ss:Type=\"Number\">%qi</Data></Cell>\n", idxStyle + 21, merge, data]];
        else
            [self write:[NSString stringWithFormat:@"    <Cell%@><Data ss:Type=\"Number\">%qi</Data></Cell>\n", merge, data]];
    }
    else
    {
        [self write:[NSString stringWithFormat:@"%qi,", data]];
    }
}

- (void)setCellDoubleValue:(double)data
{ 
    [self setCellDoubleValue:data withStyleIndex:-1 mergeAcross:0 mergeDown:0]; 
}

- (void)setCellDoubleValue:(double)data mergeAcross:(NSUInteger)mergeAcross mergeDown:(NSUInteger)mergeDown
{
    [self setCellDoubleValue:data withStyleIndex:-1 mergeAcross:mergeAcross mergeDown:mergeDown];
}

- (void)setCellDoubleValue:(double)data withStyleIndex:(int)idxStyle
{
    [self setCellDoubleValue:data withStyleIndex:idxStyle mergeAcross:0 mergeDown:0];
}
- (void)setCellDoubleValue:(double)data withStyleIndex:(int)idxStyle mergeAcross:(NSUInteger)mergeAcross mergeDown:(NSUInteger)mergeDown
{
    if (_isXml)
    {
        NSString *merge = (mergeAcross == 0 && mergeDown == 0) ? @"" : ((mergeAcross != 0 && mergeDown != 0) ? [NSString stringWithFormat:@" ss:MergeAcross=\"%lu\" ss:MergeDown=\"%lu\"", (unsigned long)mergeAcross, (unsigned long)mergeDown] : ((mergeAcross != 0) ? [NSString stringWithFormat:@" ss:MergeAcross=\"%lu\"", (unsigned long)mergeAcross] : [NSString stringWithFormat:@" ss:MergeDown=\"%lu\"", (unsigned long)mergeDown]));
        if (idxStyle != -1)
            [self write:[NSString stringWithFormat:@"    <Cell ss:StyleID=\"s%d\"%@><Data ss:Type=\"Number\">%f</Data></Cell>\n", idxStyle + 21, merge, data]];
        else
            [self write:[NSString stringWithFormat:@"    <Cell%@><Data ss:Type=\"Number\">%f</Data></Cell>\n", merge, data]];
    }
    else
    {
        [self write:[NSString stringWithFormat:@"%f,", data]];
    }
}

- (void)setCellFloatValue:(float)data
{ 
    [self setCellFloatValue:data withStyleIndex:-1 mergeAcross:0 mergeDown:0]; 
}
- (void)setCellFloatValue:(float)data mergeAcross:(NSUInteger)mergeAcross mergeDown:(NSUInteger)mergeDown
{
    [self setCellFloatValue:data withStyleIndex:-1 mergeAcross:mergeAcross mergeDown:mergeDown];
}
- (void)setCellFloatValue:(float)data withStyleIndex:(int)idxStyle
{
    [self setCellFloatValue:data withStyleIndex:idxStyle mergeAcross:0 mergeDown:0];
}
- (void)setCellFloatValue:(float)data withStyleIndex:(int)idxStyle mergeAcross:(NSUInteger)mergeAcross mergeDown:(NSUInteger)mergeDown
{
    if (_isXml)
    {
        NSString *merge = (mergeAcross == 0 && mergeDown == 0) ? @"" : ((mergeAcross != 0 && mergeDown != 0) ? [NSString stringWithFormat:@" ss:MergeAcross=\"%lu\" ss:MergeDown=\"%lu\"", (unsigned long)mergeAcross, (unsigned long)mergeDown] : ((mergeAcross != 0) ? [NSString stringWithFormat:@" ss:MergeAcross=\"%lu\"", (unsigned long)mergeAcross] : [NSString stringWithFormat:@" ss:MergeDown=\"%lu\"", (unsigned long)mergeDown]));
        if (idxStyle != -1)
            [self write:[NSString stringWithFormat:@"    <Cell ss:StyleID=\"s%d\"%@><Data ss:Type=\"Number\">%f</Data></Cell>\n", idxStyle + 21, merge, data]];
        else
            [self write:[NSString stringWithFormat:@"    <Cell%@><Data ss:Type=\"Number\">%f</Data></Cell>\n", merge, data]];
    }
    else
    {
        [self write:[NSString stringWithFormat:@"%f,", data]];
    }
}

- (NSString *)description
{
    if (_outputString) return _outputString;
    else if (_fileHandle)
    {
        unsigned long long curPos = _fileHandle.offsetInFile;
        [_fileHandle seekToFileOffset:0];
        NSData *data = [_fileHandle readDataToEndOfFile];
        NSString *ret = [[NSString alloc] initWithData:data encoding:_fileEncoding];
        [_fileHandle seekToFileOffset:curPos];
        return ret;
    }
    return @"<Empty sheet>";
}

@end

#pragma mark - 
#pragma mark - DGSpreadSheetExportAlignment

@implementation DGSpreadSheetExportAlignment

@end

#pragma mark - 
#pragma mark - DGSpreadSheetExportBorder

@implementation DGSpreadSheetExportBorder

- (id)initWithPosition:(DGSpreadSheetExportBorderPosition)position
{
    if ((self = [super init]))
    {
        _position = position;
    }
    return self;
}

- (id)initWithPosition:(DGSpreadSheetExportBorderPosition)position andColor:(UIColor *)color
{
    if ((self = [super init]))
    {
        _position = position;
        _color = color;
    }
    return self;
}

- (id)initWithPosition:(DGSpreadSheetExportBorderPosition)position andColor:(UIColor *)color andLineStyle:(DGSpreadSheetExportBorderLineStyle)lineStyle
{
    if ((self = [super init]))
    {
        _position = position;
        _color = color;
        _lineStyle = lineStyle;
    }
    return self;
}

- (id)initWithPosition:(DGSpreadSheetExportBorderPosition)position andColor:(UIColor *)color andLineStyle:(DGSpreadSheetExportBorderLineStyle)lineStyle andWeight:(double)weight
{
    if ((self = [super init]))
    {
        _position = position;
        _color = color;
        _lineStyle = lineStyle;
        _weight = weight;
    }
    return self;
}

@end

#pragma mark - 
#pragma mark - DGSpreadSheetExportInterior

@implementation DGSpreadSheetExportInterior

@end

#pragma mark - 
#pragma mark - DGSpreadSheetExportFont

@implementation DGSpreadSheetExportFont

- (id)init
{
    if ((self = [super init]))
    {
        _size = 10.0;
    }
    return self;
}

@end

#pragma mark -
#pragma mark - DGSpreadSheetExportStyle

@implementation DGSpreadSheetExportStyle

- (id)init
{
    if ((self = [super init]))
    {
        _alignment = [[DGSpreadSheetExportAlignment alloc] init];
        _borders = [NSMutableArray array];
        _interior = [[DGSpreadSheetExportInterior alloc] init];
        _font = [[DGSpreadSheetExportFont alloc] init];
    }
    return self;
}

@end
