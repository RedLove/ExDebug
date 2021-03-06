// MIT License
//
// Copyright (c) 2016 Daniel (djs66256@163.com)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

#if HOTFIX
#import <MZHotfix/MZHotfix.h>
#endif

#import "DDDebugSocketHotfixService.h"

@implementation DDDebugSocketHotfixService

- (void)receiveMessage:(DDDebugSocketMessage *)message {
    if ([message.path hasPrefix:@"hotfix"]) {
#if HOTFIX
        NSString *patchPath = [self.rootDirectory stringByAppendingPathComponent:@"hotfix.js"];
        if ([message.path isEqualToString:@"hotfix/run"]) {
            if ([message.body isKindOfClass:[NSString class]]) {
                NSString *hotfixCode = (NSString *)message.body;
                [hotfixCode writeToFile:patchPath atomically:YES encoding:NSUTF8StringEncoding error:NULL];
                __weak typeof(self) weakSelf = self;
                [MZHotfix updatePatchWithURL:[NSURL fileURLWithPath:patchPath]
                                        hash:hotfixCode.hotfix_digest
                                    complete:^(NSError *error) {
                                        typeof(weakSelf) self = weakSelf;
                                        if (!error) {
                                            [MZHotfix applyPatch];
                                            
                                            DDDebugSocketMessage *reply = message.makeReplyMessage;
                                            reply.body = @{@"message": @"OK"};
                                            [self sendMessage:reply];
                                        }
                                        else {
                                            DDDebugSocketMessage *reply = message.makeReplyMessage;
                                            reply.body = @{@"message": error.localizedDescription, @"code": @(-1)};
                                            [self sendMessage:reply];
                                        }
                                    }];
            }
        }
        else if ([message.path isEqualToString:@"hotfix/clear"]) {
            [MZHotfix clearPatch];
            [[NSFileManager defaultManager] removeItemAtPath:patchPath error:nil];
            
            DDDebugSocketMessage *reply = message.makeReplyMessage;
            reply.body = @{@"message": @"OK"};
            [self sendMessage:reply];
        }
#else
        DDDebugSocketMessage *reply = message.makeReplyMessage;
        reply.body = @{@"message": @"Do not support hotfix",
                       @"code": @-1};
        [self sendMessage:reply];
#endif
    }
}

@end
