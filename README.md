## XCActionBar -Xcode plugin

### *tl;dr*
**If** you use [Alfred](http://alfredapp.com), [LaunchBar](http://www.obdev.at/products/launchbar/index.html), [QuickSilver](http://qsapp.com/) or other similar products (and if you don't, you really should!), then you already know what this is all about.

**Else, if** you haven't and you are at least familiar with "Open Quickly" (default CMD+Shift+O), then you also know what this is all about -- it's like "Open Quickly" but for all menu bar actions, code snippets, unit tests, custom built-in actions that can operate on text or any other kind of custom action you'd like (just as long as you implement it)

**Else** Read along ... :)

###Demo:

Sorting lines demo:
![image](demo.gif)

Built-in __Add Prefix to Line(s)__ and __Add Suffix to Line(s)__ demo:
![image](demo2.gif)

###Motivation:

I always try to accomplish as much as I possibly can without ever moving my hands away from the keyboard, there's simply no other means of input that feels quite as natural or efficient.
Shortcuts are great, but there's only so many combinations of keys the average person can memorize. On top of that, the more shortcuts you have, the more likely you are to have to rely on multiple modifier key combinations, which may not always make them very comfortable to type.

It's much simpler and natural to type commands that actually describe what you want to achieve. I'm sure most people will agree that it's quicker to type `fold` or `unfold`than it is to type a four-key shortcut (which is basically as long as typing `fold`and probably doesn't feel as natural).

Note: This is preliminary documentation as this is very much work in progress.

###What can it do?

Here's the executive summary in three simple examples:

Example #1: Built in actions

1. Place the carret on the line you'd like to move up
2. Type `CMD+SHIFT+8`
3. Type `m l u`
4. Return
5. Type `CMD+OPT+7` to repeat the last action as many times as you'd like (this works for any action)

Example #2: Custom actions

1. Select a block of text
2. Type `CMD+SHIFT+8`
3. Type `nsl`
4. Return

Notice as the selected block of text is automatically surrounded with `NSLog(@"your text selection")`
Hint: type `surround` for a list of available "Surround Text With" actions

Example #3: Code snippets

1. Place the carret where you'd like to expand the snippet
2. Type `CMD+SHIFT+8`
3. Type `inline`
4. Select `C inline block as variable`
5. [fuckingblocksyntax.com](fuckingblocksyntax.com) suddenly becomes less necessary

Hopefully these short examples showcase some of the features **XCActionBar** currently supports. 
I'll continue adding features and making things generally better, so expect lots of changes in the coming weeks. 

### Searching

Action search currently operates on a few data sets:

* Menu Bar items and sub-items (recursively) 
* Code snippet library (system and user-defined)
* Custom plugin vended actions

The current searching strategy is very simple and naive but does the job quite effectively. While it doesn't yet support fuzzy matching, it's quite flexible in how it handles partial matches. Take a look at the examples above for a few examples. I'll be working on improving this very soon, but at this stage it does seem to be quite effective.

To bring up the action bar, type in the default shortcut `CMD+SHIFT+8` and enter your search terms. After performing an action, you can repeat it by typing in the repeat command shortcut `CMD+OPTION+7`.

**UPDATED**:
* You can now present/dismiss the acion bar by simply double pressing `CMD` quickly
* You can now repeat the last executed action by simply double pressing `OPTION`

The original shortcuts still work. I've also added a general configuration file `XCSurroundWithActions` which can be used to tweak these two shortcuts -- currently it only supports the following:

```
NSAlternateKeyMask
NSCommandKeyMask
NSControlKeyMask
NSFunctionKeyMask
NSShiftKeyMask    
```

This is all very much experimental so do expect changes.

### Actions

As mentioned above, the plugin comes bundled with a few custom actions. Following is a catalog of all of them and a short summary of what they do:

* `XCAddPrefixToLinesAction` **prepends** the string contents of the pasteboard to each selected line
* `XCAddSuffixToLinesAction` **appends** the string contents of the pasteboard to each selected line
* `XCDeleteLineAction` deletes the line the carret is currently positioned in
* `XCDuplicateLineAction` duplicates the line the carret is currently positioned in, or the selected lines
* `XCSortSelectionAction` performs line sorting (ascending or descending) of the selected lines
* `XCSurroundWithAction` surrounds the selected text block with an arbitrary prefix/suffix
* `XCSurroundLineWithAction` surrounds each selected line with an arbitrary prefix/suffix

I've bundled a few `XCSurroundLineWithAction` and `XCSurroundWithAction`S:

* Autorelease pool `@autoreleasepool { ... }`
* Square Brackets `[ ... ]`
* Curly Braces `{ ... }`
* Inline Block `void (^BlockVariable)(void) = ^{ ... }`
* NSLog `NSLog(@" ... ")`
* NSNumber `@( ... )`
* NSString `@" ... "`
* Parenthesis `( ... )`
* Audit Non-null region `NS_ASSUME_NONNULL_BEGIN ... NS_ASSUME_NONNULL_END`
* Pragma diagnostic region
* Double Quotes `" ... "`
* Single Quotes `' ... '`
* Try/Catch `@try{ ...} catch(NSException *exception) {}`
* While `While(expression) { ... }`
* Do/While `do { ... } while(expression)`

There's also a very __meta__ action called `XCSurroundWithSnippetAction` that surrounds the selected block of the with a snippet from the library. There are some caveats though: 
* the snippet will only show up on the list if it contains at least one `<# Token #>` (otherwise we wouldn't know what would be the prefix/suffix)
* the **first** `<# Token #>` is replaced by the selected block of text

Note: currently none of these perform any character escaping
Some of the don't really make much sense when applied to **each line** so I might strip some out in the future

Continue reading for more details on how to add your own custom actions.

### Extensibility

There are quite a lot of ideas floating around regarding extensibility, but for a first-pass implementation there's at least a little bit you can play with, in the form of `SurroundWith` actions. These are currently managed by an external property list file named `XCSurroundWithActions.plist` which can be found in the plugin's resource folder.
You're free to add your own entries or remove the stuff you don't need.

The format for each entry is a simple dictionary with the following keys:

* `XCSurroundWithActionIdentifier` a unique string identifier for the action
* `XCSurroundWithActionTitle` the action's title, displayed in the action bar
* `XCSurroundWithActionSummary` additional info that shows in the action bar's subtitle field
* `XCSurroundWithActionPrefix` the block of text that's prepended to the text you want to surround
* `XCSurroundWithActionSuffix` the block of text that's appended to the text you want to surround

If you're feeling more adventurous you can currently specify arbitrary actions by subclassing `XCCustomAction`. This is still very much in _flux_ in terms of design and is likely to change in the future, but the way this currently works is:

When you select an action from the search results list, ultimately the `- (BOOL)executeAction:(id<XCIDEContext>)context` action's method will be invoked. The `context` object provides some information about the current IDE state (active source code document, current text selection range, etc.) which is currently mostly useful for actions that need to manipulate text (pretty much all of them at the time of writing). This may change in the future.  

If you do choose to muck around and implement your own custom actions, the final step is to _register_ them. To do so, all you need to do is to add them to `XCActionBar.m` under `- (void)buildActionProviders`:

```objc
////////////////////////////////////////////////////////////////////////////////
// Built-in Actions
////////////////////////////////////////////////////////////////////////////////
NSMutableArray *textActions =
    @[
      // Duplicate/Delete Lines
      [[XCDeleteLineAction alloc] init],
      [[XCDuplicateLineAction alloc] init],
      
      // Sort Selection
      [[XCSortSelectionAction alloc] initWithSortOrder:NSOrderedAscending],
      [[XCSortSelectionAction alloc] initWithSortOrder:NSOrderedDescending],
      
      // Sort Contents
      [[XCSortContentsAction alloc] initWithSortOrder:NSOrderedAscending],
      [[XCSortContentsAction alloc] initWithSortOrder:NSOrderedDescending],
      
      // Add your custom action here
      ];
```

These actions don't yet show up in the menu bar, but they will get automatically indexed by the plugin. Soon you'll be able to manage custom actions and their groupings via an external property list file which will also be used to derive action groups under the menu bar, so stay tuned.

Feedback is greatly appreciated -- love it? hate it? suggestions? I'd love to hear about it!

Cheers,
Pedro.
