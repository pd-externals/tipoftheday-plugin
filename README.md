Tip of the Day
==============

simple plugin to display a "Tip of the Day" dialog at startup of Pd.


# Updating the Tips database
In order to get the lastest and greatest tips,
click on the "Check for updated tips" link.

#### TODO
this is actually not implemented yet :-(


# Web interface

There's an experimental web-interface for browsing the tips:

https://pd.iem.sh/tipoftheday-plugin/



# Adding new Tips

## The simple way

1. Open https://github.com/pd-externals/tipoftheday-plugin/issues/new/choose
2. Create a new "Tip of the Day" issue
3. Fill in the form
   - the only required parts are "Title" and "Detail"
   - you can provide an URL to a webpage with more information
   - you can also upload an (animated) GIF to illustrate your tip
4. Click on <kbd>Submit new issue</kbd>
5. Wait until somebody merges your new tip (or gives feedback on how to improve it)


## The manual way

0. Fork the https://github.com/pd-externals/tipoftheday-plugin repository and clone it to your computer

1. create a new TXT file in the `tips/` directory, e.g. `tips/new-tip.txt`

   ```
   TITLE   Join the community by adding more Tips-of-the-Day
   DETAIL  Everybody is invited to add one or more Tips-of-the-Day.
   DETAIL  Clicking the "More info..." link below will take you to a webpage where you can submit new tips.
   URL     https://github.com/pd-externals/tipoftheday-plugin/issues
   ```

2. sometimes a picture says more

   For patching workflows it often makes sense to illustrate the tip with an picture.
   To do so, just add an (animated, if you like) GIF image that has the same name as your TXT file (e.g. `tips/new-tip.gif`).
   Make sure that your GIF is small enough to fit into the dialog.

3. sometimes a patch says even more

   Some tips might benefit from providing an additional *tip patch* that allows users to try out the interaction described by the tip immediately. The tip patch may include extra info to help the user understand and set up the context, perform the steps in the right order, or other small bits of hand-holding. Tip patches should still conform to the general Tip format -- to teach a single thing.

   Also, tip patches should be vanilla only (no fancy external objects that might not be installed on the user's machine).

3. create a *Pull Request* with the new tip(s)


### TXT format for tips
Each line in the TXT file *must* start with a keyword,
defining the type of information that follows:
- `TITLE` a short description of the tip
   (only a single `TITLE`-line is allowed)
- `DETAIL` a longer description of the tip. for multiple lines, just add more `DETAIL` lines
- `URL` an (optional) URL that will show as `More info...`
   (only a single `URL`-line is allowed)
- `AUTHOR` who created the tip (optional)

Currently these are the only keywords supported.

### GIF format for tips

GIFs should be no larger than 550 pixels wide.
Animated GIFs will be played back at a framerate of 10fps (the settings in the GIF are ignored).

### Interactive patches for tips

You can also include a (small!) patch to illustrate a tip.
These patches should be minimal and only describe the tip at hand.

# FAQ

### This is annoying.
Since "Tip of the Day" dialogs are super-annoying for most users,
you can disable them by unchecking the "Show tips on every startup" in the dialog.

However, for new users they are helpful (that's why they are enabled by default).

You can always open the "Tip of the Day" dialog via the <kbd>Help</kbd>-menu.
