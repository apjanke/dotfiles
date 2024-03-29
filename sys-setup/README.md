# Andrew's System Setup Scripts

These are my scripts for setting up new computers and user accounts.

For the most part, these scripts are idempotent, so you can run them repeatedly on the same system or user.

This is all "alpha" quality, for personal use. All of it, including any interface or implementation, is subject to change at any time, and there are surely bugs lurking around. But I've tried to make it usable with minimal knowledge of its implementation. Bug reports are welcome if you run in to any trouble with these scripts.

## Usage

To go from a fresh macOS installation to one configured my way, do this:

First, see `manual setup steps.md` for initial manual bootstrapping stuff.

```bash
cd
mkdir -p local repos
cd repos
git clone https://github.com/apjanke/dotfiles
cd dotfiles/sys-setup

./setup-osx-system
./setup-osx-user
```

And then, optionally:

* Run `set-osx-hostname <new-name>` if you want to change your computer's name.
* Run `setup-osx-homebrew` if you're going to use [Mac Homebrew](http://brew.sh/).

For new users on a previously configured system, you only need to run `setup-osx-uer`.

## References

The macOS scripts were originally largely based on Mathias Bynens' dotfiles at <https://github.com/mathiasbynens/dotfiles> around 2015. They've evolved quite a bit since then.

Other system-setup resources used as inspiration:

* @von's mac-setup script: <https://github.com/von/mac-setup>
