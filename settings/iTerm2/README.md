# README - iTerm prefs

This is for iTerm prefs to be shared between computers.

They're not fully portable because of hardware differences: different computer form factors may need different profiles. So I've broken this up in to subdirectories where each subdir is a class of machines that can share a file well. The main difference is display DPI: regular and old pre-retina "hi-res" laptops need different font sizes to be legible. (Retina and plain non-retina might need different ones, too; dunno because I don't have a low-res non-retina at this point.)  So "retina" and "hi-res" are machine classes. I'm experimenting with moving over to more specific font-size based machine classes, so there's now a new "12pt" machine class, and a more-specific "macbook-16in" machine class. I suspect that "NNpt" point-size classes is the wrong way to go, because the same nominal font size looks different on different hardware.

This could almost be accomplished with just multiple profiles inside iTerm itself. But the default profile would need to be different on different machines, and that's not supported.

## Settings sets

I'm not calling these "profiles", because a profile is a set of settings inside an overall iTerm2 settings state, so that's ambiguous.

These live in the `settings/` subdir under here.

* New classes
  * macbook-16in - for 16" MacBook Pros.
  * imac-27in - for 5K 27" iMacs.
* Old classes
  * 12pt - for things that should display in 12-point type, regardless of hardware.
  * hi-res
  * retina

I don't remember what's different between "hi-res" and "retina". The "hi-res" class might be so old that it's from pre-Retina MacBook Pros with higher res than standard but not yet Retina displays.
