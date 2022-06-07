Tip of the Day
==============

simple plugin to display a "Tip of the Day" dialog at startup of Pd.


# Updating the Tips database
In order to get the lastest and greatest tips,
click on the "Check for updated tips" link.

#### TODO
this is actually not implemented yet :-(


# Adding new Tips

Adding tips is simple:

1. create a new TXT file in the `tips/` directory, e.g. `tips/new-tip.txt`

   ```
   TITLE   Join the community by adding more Tips-of-the-Day
   DETAIL  Everybody is invited to add one or more Tips-of-the-Day.
   DETAIL  Clicking the "More info..." link below will take you to a webpage where you can submit new tips.
   URL     https://github.com/pd-externals/tipoftheday-plugin/
   ```

   The first word in each line defines the type of information you want to add
   - `TITLE` a short description of the tip
   - `DETAIL` a longer description of the tip. for multiple lines, just add more `DETAIL` lines
   - `URL` an (optional) URL that will show as `More info...`

2. sometimes a picture says more

   For patching workflows it often makes sense to illustrate the tip with an picture.
   To do so, just add an (animated, if you like) GIF image that has the same name as your TXT file (e.g. `tips/new-tip.gif`).
   Make sure that you GIF is small enough to fit into the dialog.

3. create a *Pull Request* with the new tip(s)

# Web interface

There's an experimental web-interface for browsing the tips:

https://pd.iem.sh/tipoftheday-plugin/


# FAQ

### This is annoying.
Since "Tip of the Day" dialogs are super-annoying for most users,
you can disable them by unchecking the "Show tips on every startup" in the dialog.

However, for new users they are helpful (that's why they are enabled by default).

You can always open the "Tip of the Day" dialog via the <kbd>Help</kbd>-menu.
