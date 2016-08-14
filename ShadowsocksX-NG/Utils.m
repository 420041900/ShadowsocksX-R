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
            if ( [feature.messageString hasPrefix:@"ssr://"] ||[feature.messageString hasPrefix:@"ss://"])
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

NSString* decode64(NSString* str){

    str = [str stringByReplacingOccurrencesOfString:@"-" withString:@"+"];
    str = [str stringByReplacingOccurrencesOfString:@"_" withString:@"/"];
    if(str.length%4){
        NSInteger length = (4-str.length%4) + str.length;
        str = [str stringByPaddingToLength: length withString:@"=" startingAtIndex:0];
    }
    NSData* decodeData = [[NSData alloc] initWithBase64EncodedString:str options:0];
    NSString* decodeStr = [[NSString alloc] initWithData:decodeData encoding:NSUTF8StringEncoding];
    return decodeStr;
}


NSDictionary<NSString *, id>* ParseSSOrangeURL(NSURL* url) {
    if (!url.host) {
        return nil;
    }

    NSString *urlString = [url absoluteString];
    int i = 0;
    NSString *errorReason = nil;

    if([urlString hasPrefix:@"ss://"]){
        NSLog(@"in");
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
            urlString = [urlString stringByReplacingOccurrencesOfString:@"ss://" withString:@"" options:NSAnchoredSearch range:NSMakeRange(0, urlString.length)];
            NSRange firstColonRange = [urlString rangeOfString:@":"];
            NSRange lastColonRange = [urlString rangeOfString:@":" options:NSBackwardsSearch];
            NSRange lastAtRange = [urlString rangeOfString:@"@" options:NSBackwardsSearch];
            if (firstColonRange.length == 0) {
                errorReason = @"colon not found";
                continue;
            }
            if (firstColonRange.location == lastColonRange.location) {
                errorReason = @"only one colon";
                continue;
            }
            if (lastAtRange.length == 0) {
                errorReason = @"at not found";
                continue;
            }
            if (!((firstColonRange.location < lastAtRange.location) && (lastAtRange.location < lastColonRange.location))) {
                errorReason = @"wrong position";
                continue;
            }
            NSString *method = [urlString substringWithRange:NSMakeRange(0, firstColonRange.location)];
            NSString *password = [urlString substringWithRange:NSMakeRange(firstColonRange.location + 1, lastAtRange.location - firstColonRange.location - 1)];
            NSString *IP = [urlString substringWithRange:NSMakeRange(lastAtRange.location + 1, lastColonRange.location - lastAtRange.location - 1)];
            NSString *port = [urlString substringWithRange:NSMakeRange(lastColonRange.location + 1, urlString.length - lastColonRange.location - 1)];


            return @{@"ServerHost": IP,
                     @"ServerPort": @([port integerValue]),
                     @"Method": method,
                     @"Password": password,
                     @"obfs":@"plain",
                     @"protocol":@"origin",
                     @"obfspara":@"",
                     @"Remark":@""
                     };
        }

    }
    return nil;
}




// 解析SS URL，如果成功则返回一个与ServerProfile类兼容的dict
NSDictionary<NSString *, id>* ParseSSURL(NSURL* url) {
    if (!url.host) {return nil;}
    NSString *urlString = [url absoluteString];
    if([urlString hasPrefix:@"ssr://"]){
        urlString = [urlString stringByReplacingOccurrencesOfString:@"ssr://" withString:@"" options:NSAnchoredSearch range:NSMakeRange(0, urlString.length)];
        urlString = decode64(urlString);
        }else{
            return ParseSSOrangeURL(url);
        }

    // 服务器:端口:协议:加密方式:混淆方式:base64（密码）？obfsparam= Base64(混淆参数)&remarks=Base64(备注)


    NSArray *configArray = [urlString componentsSeparatedByString:@":"];

    if(configArray.count<5){
        return nil;
    }
    NSString *server = configArray[0];
    NSString *server_port = configArray[1];
    NSString *protocols = configArray[2];
    NSString *method = configArray[3];
    NSString *obfs = configArray[4];
    urlString = configArray[5];
    NSRange range = [urlString rangeOfString:@"/"];
    NSString *passwd_encode = [urlString substringToIndex:range.location];
    NSString *password = decode64(passwd_encode);
    urlString = [urlString substringFromIndex:range.location + 1];
    NSRange obfsrange = [urlString rangeOfString:@"obfsparam="];
    NSRange remarkRange = [urlString rangeOfString:@"remarks="];
    NSString *obfsparam = @"";
    if (obfsrange.length != 0){
        obfsparam = [urlString substringFromIndex:obfsrange.location + 10];
        if(remarkRange.length !=0){
            NSRange tmp = [obfsparam rangeOfString:@"&"];
            obfsparam = decode64([obfsparam substringToIndex:tmp.location]);
        }
    }


    NSString *remark = @"";
    if(remarkRange.length !=0){
        remark = decode64([urlString substringFromIndex:remarkRange.location+8]);
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



