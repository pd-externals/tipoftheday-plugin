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

package require http 2
# try enabling https if possible
if { [catch {package require tls} ] } {} else {
    ::tls::init -ssl2 false -ssl3 false -tls1 true
    ::http::register https 443 ::tls::socket
}
# try enabling PROXY support if possible
if { [catch {package require autoproxy} ] } {} else {
    ::autoproxy::init
    if { ! [catch {package present tls} stdout] } {
        ::http::register https 443 ::autoproxy::tls_socket
    }
}

package require pdwindow 0.1
package require pd_menucommands 0.1
package require pd_guiprefs

namespace eval ::tip-of-the-day:: {
    variable version
    # whether to use http:// or https://
    variable protocol
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

set ::tip-of-the-day::protocol "http"
if { ! [catch {package present tls} stdout] } {
    set ::tip-of-the-day::protocol "https"
}

# ######################################################################
# ################ utilities ##########################################
# ######################################################################

proc ::tip-of-the-day::add_tip {message detail} {
    lappend ::tip-of-the-day::tips [list [_ $message] [_ $detail]]
}

# ######################################################################
# ################ core ################################################
# ######################################################################



##### GUI ########
proc ::tip-of-the-day::bind_globalshortcuts {toplevel} {
    set closescript "destroy $toplevel"
    bind $toplevel <$::modifier-Key-w> $closescript
}

proc ::tip-of-the-day::syncgui {} {
    update idletasks
}

# this function gets called
# - at startup (if enabled)
# - via the menu
# by itself
proc ::tip-of-the-day::show {{tipid ""}} {
    set numtips [llength ${::tip-of-the-day::tips}]
    if { ! $numtips } {
        puts "no tips available"
        return
    }
    if { "${tipid}" eq "" } {
        set tipid [expr int(rand() * $numtips)]
    }
    puts "tip $tipid/$numtips"
    set tipid [expr $tipid % $numtips]
    foreach {title body} [lindex ${::tip-of-the-day::tips} $tipid] {break}
    tk_messageBox -title [_ "Tip of the Day"] -type ok \
        -message $title -detail $body
    return

    set winid .tip-of-the-day
    destroy $winid

    toplevel $winid -class DialogWindow
    set ::tip-of-the-day::winid $winid
    wm title $winid [_ "Tip of the Day"]
    wm geometry $winid 670x550
    wm minsize $winid 230 360
    wm transient $winid
    $winid configure -padx 10 -pady 5

    if {$::windowingsystem eq "aqua"} {
        $winid configure -menu $::dialog_menubar
    }

    frame $winid.searchbit
    pack $winid.searchbit -side top -fill "x"

    entry $winid.searchbit.entry -font 18 -relief sunken -highlightthickness 1 -highlightcolor blue
    pack $winid.searchbit.entry -side left -padx 6 -fill "x" -expand true
    bind $winid.searchbit.entry <Key-Return> "::tip-of-the-day::initiate_search $winid"
    bind $winid.searchbit.entry <KeyRelease> "::tip-of-the-day::update_searchbutton $winid"
    focus $winid.searchbit.entry
    button $winid.searchbit.button -text [_ "Show all"] -default active -command "::tip-of-the-day::initiate_search $winid"
    pack $winid.searchbit.button -side right -padx 6 -pady 3 -ipadx 10

    frame $winid.objlib
    pack $winid.objlib -side top -fill "x"
    label $winid.objlib.label -text [_ "Search for: "]
    radiobutton $winid.objlib.libraries -text [_ "libraries"] -variable ::tip-of-the-day::searchtype -value libraries
    radiobutton $winid.objlib.objects -text [_ "objects"] -variable ::tip-of-the-day::searchtype -value objects
    radiobutton $winid.objlib.both -text [_ "both"] -variable ::tip-of-the-day::searchtype -value name
    foreach x {label libraries objects both} {
        pack $winid.objlib.$x -side left -padx 6
    }
    # for Pd that supports it, add a 'translation' radio
    if {[uplevel 2 info procs add_to_helppaths] ne ""} {
        radiobutton $winid.objlib.translations -text [_ "translations"] -variable ::tip-of-the-day::searchtype -value translations
        pack $winid.objlib.translations -side left -padx 6
    }
    frame $winid.warning
    pack $winid.warning -side top -fill "x"
    label $winid.warning.label -text [_ "Only install externals uploaded by people you trust."]
    pack $winid.warning.label -side left -padx 6

    text $winid.results -takefocus 0 -cursor hand2 -height 100 -yscrollcommand "$winid.results.ys set"
    scrollbar $winid.results.ys -orient vertical -command "$winid.results yview"
    pack $winid.results.ys -side right -fill "y"
    pack $winid.results -side top -padx 6 -pady 3 -fill both -expand true

    frame $winid.progress
    pack $winid.progress -side top -fill "x"
    if { ! [ catch {
        ttk::progressbar $winid.progress.bar -orient horizontal -length 640 -maximum 100 -mode determinate -variable ::tip-of-the-day::progressvar } stdout ] } {
        pack $winid.progress.bar -side top -fill "x"
        proc ::tip-of-the-day::progress {x} { set ::tip-of-the-day::progressvar $x }
        label ${winid}.progress.label -textvariable ::tip-of-the-day::progresstext -padx 0 -borderwidth 0
        place ${winid}.progress.label -in ${winid}.progress.bar -x 1
    }

    frame $winid.status
    pack $winid.status -side bottom -fill "x" -pady 3
    label $winid.status.label -textvariable ::tip-of-the-day::statustext -relief sunken -anchor "w"
    pack $winid.status.label -side bottom -fill "x"

    set m .deken_moremenu
    if { [winfo exists $m] } {
        destroy $m
    }
    set m [menu $m]
    $m add command -label [_ "Preferences..." ]  -command "::tip-of-the-day::preferences::show"
    $m add command -label [_ "Install DEK file..." ]  -command "::tip-of-the-day::install_package_from_file"

    button $winid.status.installdek -text [_ "More..." ] -command "tk_popup $m \[winfo pointerx $winid\] \[winfo pointery $winid\]"
    pack $winid.status.installdek -side right -padx 6 -pady 3 -ipadx 10


    ::tip-of-the-day::bind_globalshortcuts $winid
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
        $mymenu add separator
        $mymenu add command -label [_ "Tip of the Day"] -command {::tip-of-the-day::show}
    }


    ::tip-of-the-day::add_tip "${::modifier}-Click messages in the Pd-console to find its origin." "You can find the source of many errors and other printouts in the Pd-console by ${::modifier}-clicking the line."
}

::tip-of-the-day::initialize
}
