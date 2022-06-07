# META NAME Tip-of-the-Day
# META DESCRIPTION Display a short tip
# META AUTHOR <IOhannes m zmölnig> zmoelnig@iem.at
# ex: set setl sw=2 sts=2 et

# The minimum version of TCL that allows the plugin to run
package require Tcl 8.4
# If Tk or Ttk is needed
#package require Ttk
# Any elements of the Pd GUI that are required
# + require everything and all your script needs.
#   If a requirement is missing,
#   Pd will load, but the script will not.

package require pdwindow 0.1
package require pd_menucommands 0.1
package require pd_guiprefs

namespace eval ::tip-of-the-day:: {
    variable version
    variable tips
    variable current_tip
}

## only register this plugin if there isn't any newer version already registered
## (if ::tip-of-the-day::version is defined and is higher than our own version)
proc ::tip-of-the-day::versioncheck {version} {
    if { [info exists ::tip-of-the-day::version ] } {
        set v0 [split ${::tip-of-the-day::version} "."]
        set v1 [split $version "."]
        foreach x $v0 y $v1 {
            if { $x > $y } {
                set msg [format [_ "\[Tip of the Day\] installed version \[%1\$s\] > %2\$s...skipping!" ] $::tip-of-the-day::version $version ]
                ::pdwindow::debug "${msg}\n"
                return 0
            }
            if { $x < $y } {
                set msg [format [_ "\[Tip of the Day\] installed version \[%1\$s\] < %2\$s...overwriting!" ] $::tip-of-the-day::version $version ]
                ::pdwindow::debug "$msg\n"
                set ::tip-of-the-day::version $version
                return 1
            }
        }
        set msg [format [_ "\[Tip of the Day\] installed version \[%1\$s\] == %2\$s...skipping!" ] $::tip-of-the-day::version $version ]
        ::pdwindow::debug "${msg}\n"
        return 0
    }
    set ::tip-of-the-day::version $version
    return 1
}

## put the current version of this package here:
if { [::tip-of-the-day::versioncheck 0.0.0] } {

## add tip (without duplicates)
proc ::tip-of-the-day::add_tip {message detail url image} {
    foreach tip ${::tip-of-the-day::tips} {
        foreach {m d} $tip {break}
        if { ${m} eq ${message} && ${d} eq ${detail} } {
            #puts "drop dupe: ${message}"
            return
        }
    }
    lappend ::tip-of-the-day::tips [list $message $detail $url $image]
}

## load tip from filename
proc ::tip-of-the-day::load {filename} {
    if {[catch {set fp [open $filename r]}]} {
        #puts "unable to open $filename"
        return
    }
    set title {}
    set detail {}
    set url {}
    set compat 1
    while { [gets $fp data] >= 0 } {
        set id [lindex $data 0]
        set data [lrange $data 1 end]
        if { "TITLE" eq $id } {
            set title $data
        } elseif { "DETAIL" eq $id } {
            set detail $data
        } elseif { "URL" eq $id } {
            set url $data
        } elseif { "COMPAT" eq $id } {
            # for now ignore compatibility settings
            # LATER use it to exclude tips if they are for Pd-versions that don't apply
        } else {
            #puts "ignoring unknown ID '$id'"
        }
    }
    close $fp
    set image "[file rootname $filename].gif"
    if {! [file exists $image] } {
        set image {}
    }
    if { $compat && "${title}{$detail}" ne "" } {
        ::tip-of-the-day::add_tip $title $detail $url $image
    }
}

# ######################################################################
# ################ core ################################################
# ######################################################################



##### GUI ########
proc ::tip-of-the-day::bind_globalshortcuts {toplevel} {
    bind $toplevel <$::modifier-Key-w> [list destroy $toplevel]
}

## save preferences (whether the user wants automatic tips on startup or not)
proc ::tip-of-the-day::save_prefs {} {
    ::pd_guiprefs::write tipoftheday_startup ${::tip-of-the-day::run_at_startup}
}


# puts the text/images of the given $tipid into $textwin
# ($textwin is a reference to a 'text' widget)
proc ::tip-of-the-day::update_tip_info {textwin {tipid {}}} {
    if { ! [winfo exists $textwin] } {return}

    if { {} eq $tipid} {
        set tipid ${::tip-of-the-day::current_tip}
    }
    foreach {title detail url image} [lindex ${::tip-of-the-day::tips} $tipid] {break}

    $textwin configure -state normal
    $textwin delete 1.0 end

    if { {} ne ${title} } {
        $textwin insert end "${title}" title
        $textwin insert end "\n\n"
    }
    $textwin insert end ${detail}

    if { {} ne ${url} } {
        $textwin insert end "\n\n"
        $textwin insert end [_ "More..."] moreurl
    }
    $textwin configure -state disabled

    # set the internal counter to the next tip
    set tipid [expr ${tipid} + 1]
    set ::tip-of-the-day::current_tip [expr $tipid %  [llength ${::tip-of-the-day::tips}] ]


    # make a nice window title
    set msg [_ "Tip of the Day"]
    wm title [winfo toplevel $textwin] "$msg #${tipid}"
}

# create a new messagebox
proc ::tip-of-the-day::messageBox {{tipid {}}} {
    # we want more than a 'tk_titleBox' can offer...
    # - non-modal
    # - "Next" button
    # - "..." button that offers a pulldown with
    #   - "Fetch new tips from the internet"
    #   - "Show Tip-of-the-Day on every startup" (checkbox)
    set winid .tip-of-the-day
    destroy $winid

    toplevel $winid -class DialogWindow
    set ::tip-of-the-day::winid $winid
    wm title $winid [_ "Tip of the Day"]
    wm geometry $winid 670x550
    wm minsize $winid 230 360
    wm resizable $winid 1 0
    wm transient $winid
    $winid configure -padx 10 -pady 5
    focus $winid
    bell -displayof $winid -nice

    if {$::windowingsystem eq "aqua"} {
        $winid configure -menu $::dialog_menubar
    }

    frame $winid.totd
    pack $winid.totd -side top -fill "both"

    set msgid $winid.totd.tip
    text $msgid -padx 10 -pady 10 -wrap word
    pack $msgid

    $msgid tag configure title -font "-weight bold"
    $msgid tag configure moreurl -foreground blue

    $msgid tag bind moreurl <1> "pd_menucommands::menu_openfile https://deken.puredata.info/"
    $msgid tag bind moreurl <Enter> "$msgid tag configure moreurl -underline 1; $msgid configure -cursor $::cursor_runmode_clickme"
    $msgid tag bind moreurl <Leave> "$msgid tag configure moreurl -underline 0; $msgid configure -cursor xterm"


    ######################################################
    # user interaction: disable TOD, udpate TOD, Close, Next
    # fopcus Close

    frame $winid.nb
    pack $winid.nb -side bottom -fill "x" -padx 2m -pady 2m -ipadx 2m

    set bt [frame $winid.nb.config]
    pack $bt -side left -fill "x"
    checkbutton $bt.startup -text "Show tips on every startup" -anchor e \
        -variable ::tip-of-the-day::run_at_startup \
        -command [list ::tip-of-the-day::save_prefs]
    pack $bt.startup -anchor w -side top -expand 1 -fill "x" -padx 15 -ipadx 10
    label $bt.update -text "Check for updated tips" -fg blue -cursor hand2 -anchor e
    #pack $bt.update -side top -expand 1 -fill "x" -padx 15 -ipadx 10
    bind $bt.update "<Button-1>" [list ::pdwindow::error "Tip-of-the-Day update not implemented yet\n"]

    # Close/Next buttons
    set bt [frame $winid.nb.buttons]
    pack $bt -side right -fill "x"
    button $bt.close -text [_ "Close" ] \
        -command [list destroy $winid]
    pack $bt.close -side left -expand 1 -fill "x"
    button $bt.next -text [_ "Next tip" ] \
        -command [list ::tip-of-the-day::update_tip_info $msgid]
    pack $bt.next -side left -expand 1 -fill "x" -padx 10
    focus $bt.close

    ::tip-of-the-day::bind_globalshortcuts $winid

    ::tip-of-the-day::update_tip_info $msgid $tipid
}
# this function gets called
# - at startup (if enabled)
# - via the menu
proc ::tip-of-the-day::show {{tipid ""}} {
    set numtips [llength ${::tip-of-the-day::tips}]
    if { ! $numtips } {
        ::pdwindow::post [_ "no tips-of-the-day available" ]
        ::pdwindow::post "\n"
        return
    }
    if { "${tipid}" eq "" } {
        set tipid [expr int(rand() * $numtips)]
    }
    ::tip-of-the-day::messageBox $tipid
    return
}


proc ::tip-of-the-day::initialize {} {
    # console message to let them know we're loaded
    ## but only if we are being called as a plugin (not as built-in)
    if { "" != "$::current_plugin_loadpath" } {
        ::pdwindow::post [format [_ "\[Tip of the Day\] loaded tipoftheday-plugin.tcl from %s." ] $::current_plugin_loadpath ]
        ::pdwindow::post "\n"
    }

    # create an entry for our search in the "help" menu (or re-use an existing one)
    set mymenu .menubar.help
    if { [catch {
        $mymenu entryconfigure [_ "Tip of the Day"] -command {::tip-of-the-day::show}
    } _ ] } {
        #$mymenu add separator
        $mymenu add command -label [_ "Tip of the Day"] -command {::tip-of-the-day::show}
    }

    lappend ::tip-of-the-day::tips
    foreach pathdir [concat $::current_plugin_loadpath $::sys_temppath $::sys_searchpath $::sys_staticpath] {
        set dir [file normalize [file join $pathdir tips]]
        if { ! [file isdirectory $dir]} {continue}
        foreach filename [glob -directory $dir -nocomplain -types {f} -- "*.txt"] {
            ::tip-of-the-day::load $filename
        }
    }

    set startup [::pd_guiprefs::read tipoftheday_startup]
    if { [catch {set startup [expr bool($startup) ] } ] } {
        set startup 1
    }
    set ::tip-of-the-day::run_at_startup $startup
    if { $startup } {
        after idle ::tip-of-the-day::show
    }

}

::tip-of-the-day::initialize
}