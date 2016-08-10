//
//  QRCodeUtils.m
//  ShadowsocksX-NG
//
//  Created by 邱宇舟 on 16/6/8.
//  Copyright © 2016年 qiuyuzhou. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreImage/CoreImage.h>

void ScanQRCodeOnScreen() {
    /* displays[] Quartz display ID's */
    CGDirectDisplayID   *displays = nil;
    
    CGError             err = CGDisplayNoErr;
    CGDisplayCount      dspCount = 0;
    
    /* How many active displays do we have? */
    err = CGGetActiveDisplayList(0, NULL, &dspCount);
    
    /* If we are getting an error here then their won't be much to display. */
    if(err != CGDisplayNoErr)
    {
        NSLog(@"Could not get active display count (%d)\n", err);
        return;
    }
    
    /* Allocate enough memory to hold all the display IDs we have. */
    displays = calloc((size_t)dspCount, sizeof(CGDirectDisplayID));
    
    // Get the list of active displays
    err = CGGetActiveDisplayList(dspCount,
                                 displays,
                                 &dspCount);
    
    /* More error-checking here. */
    if(err != CGDisplayNoErr)
    {
        NSLog(@"Could not get active display list (%d)\n", err);
        return;
    }
    
    NSMutableArray* foundSSUrls = [NSMutableArray array];
    
    CIDetector *detector = [CIDetector detectorOfType:@"CIDetectorTypeQRCode"
                                              context:nil
                                              options:@{ CIDetectorAccuracy:CIDetectorAccuracyHigh }];
    
    for (unsigned int displaysIndex = 0; displaysIndex < dspCount; displaysIndex++)
    {
        /* Make a snapshot image of the current display. */
        CGImageRef image = CGDisplayCreateImage(displays[displaysIndex]);
        NSArray *features = [detector featuresInImage:[CIImage imageWithCGImage:image]];
        for (CIQRCodeFeature *feature in features) {
//            NSLog(@"%@", feature.messageString);
            if ( [feature.messageString hasPrefix:@"ssr://"] )
            {
                [foundSSUrls addObject:[NSURL URLWithString:feature.messageString]];
            }
        }
    }
    
    free(displays);
    
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"NOTIFY_FOUND_SS_URL"
     object:nil
     userInfo: @{ @"urls": foundSSUrls,
                  @"source": @"qrcode"
                 }
     ];
}

NSString* decode(NSString* str){
    NSData* decodeData = [[NSData alloc] initWithBase64EncodedString:str options:0];
    NSString* decodeStr = [[NSString alloc] initWithData:decodeData encoding:NSASCIIStringEncoding];
    return decodeStr;
}

// 解析SS URL，如果成功则返回一个与ServerProfile类兼容的dict
NSDictionary<NSString *, id>* ParseSSURL(NSURL* url) {





    if (!url.host) {
        return nil;
    }
    
    NSString *urlString = [url absoluteString];
    int i = 0;
    NSString *errorReason = nil;
    while(i < 2) {
        if (i == 1) {
            NSString* host = url.host;
            if ([host length]%4!=0) {
                int n = 4 - [host length]%4;
                if (1==n) {
                    host = [host stringByAppendingString:@"="];
                } else if (2==n) {
                    host = [host stringByAppendingString:@"=="];
                }
            }
            NSData *data = [[NSData alloc] initWithBase64EncodedString:host options:0];
            NSString *decodedString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            urlString = decodedString;
        }
        i++;
        urlString = [urlString stringByReplacingOccurrencesOfString:@"ssr://" withString:@"" options:NSAnchoredSearch range:NSMakeRange(0, urlString.length)];

//        服务器:端口:协议:加密方式:混淆方式:base64（密码）？obfsparam= Base64(混淆参数)&remarks=Base64(备注)




        NSRange ColonRange = [urlString rangeOfString:@":"];
        if (ColonRange.length == 0) {
            errorReason = @"colon not found";
            continue;
        }

        NSString *server = [urlString substringWithRange:NSMakeRange(0, ColonRange.location)]; //服务器

        urlString = [urlString substringFromIndex:ColonRange.location + 1];
        ColonRange = [urlString rangeOfString:@":"];
        if(ColonRange.length == 0){continue;}
        NSString *server_port = [urlString substringWithRange:NSMakeRange(0, ColonRange.location)]; //端口
        urlString = [urlString substringFromIndex:ColonRange.location + 1];


        ColonRange = [urlString rangeOfString:@":"];
        if(ColonRange.length == 0){continue;}
        NSString *protocols = [urlString substringWithRange:NSMakeRange(0, ColonRange.location)]; //协议
        urlString = [urlString substringFromIndex:ColonRange.location + 1];

        ColonRange = [urlString rangeOfString:@":"];
        if(ColonRange.length == 0){continue;}
        NSString *method = [urlString substringWithRange:NSMakeRange(0, ColonRange.location)]; //协议
        urlString = [urlString substringFromIndex:ColonRange.location + 1];

        ColonRange = [urlString rangeOfString:@":"];
        if(ColonRange.length == 0){continue;}
        NSString *obfs = [urlString substringWithRange:NSMakeRange(0, ColonRange.location)]; //混淆
        urlString = [urlString substringFromIndex:ColonRange.location + 1];


        ColonRange = [urlString rangeOfString:@"/"];
        if(ColonRange.length == 0){continue;}
        NSString *pwd_encode = [urlString substringWithRange:NSMakeRange(0, ColonRange.location)]; //密码
        NSString *password = decode(pwd_encode);
        urlString = [urlString substringFromIndex:ColonRange.location + 1];


        NSRange obfsrange = [urlString rangeOfString:@"obfsparam="];
        NSRange remarkRange = [urlString rangeOfString:@"&remarks="];

        NSString *obfsparam = @"";
        if (obfsrange.length != 0){
            obfsparam = [urlString substringFromIndex:obfsrange.location + 10];
            if(remarkRange.length !=0){
                NSRange tmp = [obfsparam rangeOfString:@"&"];
                obfsparam = decode([obfsparam substringToIndex:tmp.location]);
            }
        }
        NSString *remark = @"";
        if(remarkRange.length !=0){
            remark = decode([urlString substringFromIndex:remarkRange.location+9]);
        }


        return @{@"ServerHost": server,
                 @"ServerPort": @([server_port integerValue]),
                 @"Method": method,
                 @"Password": password,
                 @"Remark":remark,
                 @"obfs":obfs,
                 @"protocol":protocols,
                 @"obfspara":obfsparam
                 };
    }
    return nil;
}


