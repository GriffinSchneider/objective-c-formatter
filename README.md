objective-c-formatter
=====================

Extremely unintelligent Objective-C formatter. Does some assorted regex-ing to format Objective-C in a manner that I find pleasing.

Almost all formatting operations are currently one-line-at-a-time, and don't take any context into account. This means that the formatter does not attempt to re-indent code, although it will replace all tabs with 4 spaces. The one exception is that '{' characters that are alone on a line will be moved up to the previous line, to turn this:
```objective-c
if (stuff)
{
    [self doSomeThings];
}
```
into this:
```objective-c
if (stuff) {
    [self doSomeThings];
}
```

Currently, the formatter focuses on property and method declarations.
