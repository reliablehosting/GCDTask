GCDTask is a wrapper for NSTask that allows for handling input, output and error streams just by providing a block to handle it.

# GCDTask — NSTask with blocks and GCD.

**GCDTask** is a wrapper for `NSTask` that tries to use GCD as much as possible and provide a simple block-based interface for use.

Example usage:

```objective-c

    GCDTask* pingTask = [[GCDTask alloc] init];
    
    [pingTask setArguments:@[@"-c",@"4",@"8.8.8.8"]];
    [pingTask setLaunchPath:@"/sbin/ping"];
    
    [pingTask launchWithOutputBlock:^(NSData *stdOutData) {
        NSString* output = [[NSString alloc] initWithData:stdOutData encoding:NSUTF8StringEncoding];
        NSLog(@"OUT: %@", output);
    } andErrorBlock:^(NSData *stdErrData) {
        NSString* output = [[NSString alloc] initWithData:stdErrData encoding:NSUTF8StringEncoding];
        NSLog(@"ERR: %@", output);
    } onLaunch:^{
        NSLog(@"Task has started running.");
    } onExit:^(int exitStatus) {
        NSLog(@"Task has now quit. Exit status %d",exitStatus);
    }];

```

## License

View the LICENSE file for more info.
