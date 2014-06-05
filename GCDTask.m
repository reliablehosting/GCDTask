//
//  GCDTask.m
//
//  Author: Darvell Long
//  Copyright (c) 2014 Reliablehosting.com. All rights reserved.
//

#import "GCDTask.h"

@implementation GCDTask

- (id) init
{
    /* Check for a runloop. If it doesn't exist, throw an exception. */
    /* TODO: Attempt to read the file handle on GCD only if there is no run loop. We should support dispatch_main() only applications anyway, that's true GCD. */
    if([NSRunLoop currentRunLoop] == nil)
    {
        @throw [NSException exceptionWithName:@"GCDTASK_NO_RUNLOOP" reason:@"No run loop was detected. If you are using this in a terminal application or daemon, ensure you're using CFRunLoopRun() over dispatch_main()." userInfo:nil];
    }
    
    return [super init];
    
}

- (void) launchWithOutputBlock: (void (^)(NSData* stdOutData)) stdOut
                 andErrorBlock: (void (^)(NSData* stdErrData)) stdErr
                      onLaunch: (void (^)()) launched
                        onExit: (void (^)()) exit
{
    executingTask = [[NSTask alloc] init];
 
    /* Set launch path. */
    [executingTask setLaunchPath:_launchPath];
    
    /* Set arguments. */
    [executingTask setArguments:_arguments];
    
    
    /* Setup pipes */
    stdinPipe = [NSPipe pipe];
    stdoutPipe = [NSPipe pipe];
    stderrPipe = [NSPipe pipe];
    
    [executingTask setStandardInput:stdinPipe];
    [executingTask setStandardOutput:stdoutPipe];
    [executingTask setStandardError:stderrPipe];
    
    /* Set current directory, just pass on our actual CWD. */
    /* TODO: Potentially make this changeable? Surely there's probably a nicer way to get the CWD too. */
    [executingTask setCurrentDirectoryPath:[[[NSFileManager alloc] init] currentDirectoryPath]];

    
    stdoutObserver = [[NSNotificationCenter defaultCenter] addObserverForName:NSFileHandleDataAvailableNotification object:[stdoutPipe fileHandleForReading] queue:nil usingBlock:^(NSNotification *note)
    {
        NSFileHandle* outHandle = (NSFileHandle*) [note object];
        NSData* data = [outHandle availableData];
        
        if([data length])
        {
            GCDDebug(@"Data recieved from task stdout.\n%@",data);
            if(!_hasExecuted)
            {
                if(launched)
                    launched();
                
                _hasExecuted = TRUE;
            }
            
            if(stdOut)
            {
                stdOut(data);
            }
            [outHandle waitForDataInBackgroundAndNotify];
        }
        else /* No data object means the pipe is closed generally, meaning execution is over. */
        {
            /* Remove observers and call exit. */
            [[NSNotificationCenter defaultCenter] removeObserver:stdoutObserver];
            [[NSNotificationCenter defaultCenter] removeObserver:stderrObserver];

            if(exit)
            {
                exit();
                _hasExecuted = FALSE;
            }
            stdoutObserver = nil; // Force ARC dealloc/cleanup.
        }
    }];
    
    /* This is basically copy/paste of stdout sending. */
    stderrObserver = [[NSNotificationCenter defaultCenter] addObserverForName:NSFileHandleDataAvailableNotification object:[stderrPipe fileHandleForReading] queue:nil usingBlock:^(NSNotification *note)
                      {
                          NSFileHandle* errHandle = (NSFileHandle*) [note object];
                          NSData* data = [errHandle availableData];
                          
                          if([data length])
                          {
                              GCDDebug(@"Data recieved from task stderr.\n%@",data);

                              if(stdErr)
                              {
                                  stdErr(data);
                              }
                              [errHandle waitForDataInBackgroundAndNotify];
                          }
                          else
                          {
                          }
                      }];
    [[stdoutPipe fileHandleForReading] waitForDataInBackgroundAndNotify];
    [[stderrPipe fileHandleForReading] waitForDataInBackgroundAndNotify];
    [executingTask launch];
}

- (BOOL) WriteStringToStandardInput: (NSString*) input
{
    return [self WriteDataToStandardInput:[input dataUsingEncoding:NSUTF8StringEncoding]];
}


/* Currently synchronous. TODO: Async fun! */
- (BOOL) WriteDataToStandardInput: (NSData*) input
{
    if (!stdinPipe || stdinPipe == nil)
    {
        GCDDebug(@"Standard input pipe does not exist.");
        return NO;
    }
    
    [[stdinPipe fileHandleForWriting] writeData:input];
    return YES;
}

/* If you don't like setting your own array. You really should never have a use for this. */
- (void) AddArgument: (NSString*) argument
{
    NSMutableArray* temp = [NSMutableArray arrayWithArray:_arguments];
    [temp addObject:argument];
    [self setArguments:temp];
}


@end
