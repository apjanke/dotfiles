# README - iTerm prefs

This is for iTerm prefs to be shared between computers.

They're not fully portable because of hardware differences: different computer form factors may need different profiles. So I've broken this up in to subdirectories where each subdir is a class of machines that can share a file well. The main difference is display DPI: regular and old pre-retina "hi-res" laptops need different font sizes to be legible. (Retina and plain non-retina might need different ones, too; dunno because I don't have a low-res non-retina at this point.)  So "retina" and "hi-res" are machine classes. I'm experimenting with moving over to more specific font-size based machine classes, so there's now a new "12pt" machine class.

This could almost be accomplished with just multiple profiles inside iTerm itself. But the default profile would need to be different on different machines, and that's not supported.
