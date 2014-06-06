//
//  GCDTask.m
//
//  Author: Darvell Long
//  Copyright (c) 2014 Reliablehosting.com. All rights reserved.
//

#import "GCDTask.h"
#define GCDTASK_BUFFER_MAX 1024

@implementation GCDTask

- (void) launchWithOutputBlock: (void (^)(NSData* stdOutData)) stdOut
                 andErrorBlock: (void (^)(NSData* stdErrData)) stdErr
                      onLaunch: (void (^)()) launched
                        onExit: (void (^)()) exit
{
    executingTask = [[NSTask alloc] init];
 
    /* Set launch path. */
    [executingTask setLaunchPath:[_launchPath stringByStandardizingPath]];
    
    if (![[NSFileManager defaultManager] isExecutableFileAtPath:[executingTask launchPath]])
    {
        @throw [NSException exceptionWithName:@"GCDTASK_INVALID_EXECUTABLE" reason:@"There is no executable at the path set." userInfo:nil];
    }

    /* Clean then set arguments. */
    for (id arg in _arguments)
    {
        if([arg class] != [NSString class])
        {
            NSMutableArray* cleanedArray = [[NSMutableArray alloc] init];
            /* Clean up required! */
            for (id arg in _arguments)
            {
                [cleanedArray addObject:[NSString stringWithFormat:@"%@",arg]];
            }
            [self setArguments:cleanedArray];
            break;
        }
    }
    
    
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

    
    /* Ensure the pipes are non-blocking so GCD can read them correctly. */
    fcntl([stdoutPipe fileHandleForReading].fileDescriptor, F_SETFL, O_NONBLOCK);
    fcntl([stderrPipe fileHandleForReading].fileDescriptor, F_SETFL, O_NONBLOCK);
    
    /* Setup a dispatch source for both descriptors. */
    _stdoutSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_READ,[stdoutPipe fileHandleForReading].fileDescriptor, 0, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0));
    _stderrSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_READ,[stderrPipe fileHandleForReading].fileDescriptor, 0, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0));
    
    /* Set stdout source event handler to read data and send it out. */
    dispatch_source_set_event_handler(_stdoutSource, ^ {
        size_t estimatedBlockSize = dispatch_source_get_data(_stdoutSource);
        ssize_t bytesRead;
        
        if(!_hasExecuted)
        {
            if(launched)
                launched();
            _hasExecuted = TRUE;
        }
        
        if(estimatedBlockSize == 0 && ![executingTask isRunning])
        {
            if(exit)
            {
                exit();
            }
            _hasExecuted = FALSE;
            dispatch_source_cancel(_stdoutSource);
            dispatch_source_cancel(_stderrSource);

        }
        
        while(true)
        {
            char buffer[estimatedBlockSize + GCDTASK_BUFFER_MAX];
            bytesRead = read((int)dispatch_source_get_handle(_stdoutSource), buffer, estimatedBlockSize + GCDTASK_BUFFER_MAX);
            if(bytesRead == 0)
            {
                break;
            }
            if (bytesRead != -1)
            {
                if(stdOut)
                {
                    stdOut([NSData dataWithBytes:buffer length:bytesRead]);
                }
                break;
            }
        }
    });
    
    /* Same thing for stderr. */
    dispatch_source_set_event_handler(_stderrSource, ^ {
        size_t estimatedBlockSize = dispatch_source_get_data(_stderrSource);
        ssize_t bytesRead;
        
        while(true)
        {
            char buffer[estimatedBlockSize + GCDTASK_BUFFER_MAX];
            bytesRead = read((int)dispatch_source_get_handle(_stdoutSource), buffer, estimatedBlockSize + GCDTASK_BUFFER_MAX);
            if(bytesRead == 0)
            {
                break;
            }
            if (bytesRead != -1)
            {
                if(stdErr)
                {
                    stdErr([NSData dataWithBytes:buffer length:bytesRead]);
                }
                break;
            }
        }
    });

    
    dispatch_resume(_stdoutSource);
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
