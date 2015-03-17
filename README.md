## XCActionBar -Xcode plugin

### *tl;dr*
**If** you use [Alfred](http://alfredapp.com), [LaunchBar](http://www.obdev.at/products/launchbar/index.html), [QuickSilver](http://qsapp.com/) or other similar products (and if you don't, you really should!), then you already know what this is all about.

**Else, if** you haven't and you are at least familiar with "Open Quickly" (default CMD+Shift+O), then you also know what this is all about -- it's like "Open Quickly" but for all menu bar actions, code snippets, unit tests, custom built-in actions that can operate on text or any other kind of custom action you'd like (just as long as you implement it)

**Else** Read along ... :)

###Motivation:

I always try to accomplish as much as I possibly can without every moving my hands away from the keyboard, there's simply no other means of input that feels quite as natural or efficient.
Shortcuts are great, but there's only so many combinations of keys the average person can memorize. On top of that, the more shortcuts you have, the more likely you are to have to rely on multiple modifier key combinations, which may not always make them very comfortable to type.

It's much simpler and natural to type command that actually describe what you want to achieve. I'm sure most people will agree that's quicker to type `fold` or `unfold`than it is to type a four-key shortcut (which is basically as long as typing `fold`and probably doesn't feel as natural).

Note: This is preliminary documentation as this is very much work in progress.

###What can it do?

Here's the executive summary in three examples:

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

Feedback is greatly appreciated -- love it? hate it? suggestions? I'd love to hear about it!

Cheers,
Pedro.
