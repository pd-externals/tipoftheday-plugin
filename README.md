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

Adding tips is simple:

1. create a new TXT file in the `tips/` directory, e.g. `tips/new-tip.txt`

   ```
   TITLE   Join the community by adding more Tips-of-the-Day
   DETAIL  Everybody is invited to add one or more Tips-of-the-Day.
   DETAIL  Clicking the "More info..." link below will take you to a webpage where you can submit new tips.
   URL     https://github.com/pd-externals/tipoftheday-plugin/
   ```

2. sometimes a picture says more

   For patching workflows it often makes sense to illustrate the tip with an picture.
   To do so, just add an (animated, if you like) GIF image that has the same name as your TXT file (e.g. `tips/new-tip.gif`).
   Make sure that your GIF is small enough to fit into the dialog.

3. create a *Pull Request* with the new tip(s)


### TXT format for tips
Each line in the TXT file *must* start with a keyword,
defining the type of information that follows:
- `TITLE` a short description of the tip
   (only a single `TITLE`-line is allowed)
- `DETAIL` a longer description of the tip. for multiple lines, just add more `DETAIL` lines
- `URL` an (optional) URL that will show as `More info...`
   (only a single `URL`-line is allowed)

Currently these are the only keywords supported.

### GIF format for tips

GIFs should be no larger than 650x533 pixels.
Animated GIFs will be played back at a framerate of 10fps (the settings in the GIF are ignored).


# FAQ

### This is annoying.
Since "Tip of the Day" dialogs are super-annoying for most users,
you can disable them by unchecking the "Show tips on every startup" in the dialog.

However, for new users they are helpful (that's why they are enabled by default).

You can always open the "Tip of the Day" dialog via the <kbd>Help</kbd>-menu.
