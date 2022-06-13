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

    variable tipsdirs
    variable tips
    variable current_tip

    variable images
    variable imageloop
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
    proc ::tip-of-the-day::add_tip {message detail {author {}} {url {}} {image {}} {patch {}}} {
    foreach tip ${::tip-of-the-day::tips} {
        foreach {m d} $tip {break}
        if { ${m} eq ${message} && ${d} eq ${detail} } {
            #puts "drop dupe: ${message}"
            return 0
        }
    }
    set tip [list $message $detail $author $url $image $patch]
    lappend ::tip-of-the-day::tips $tip
    return 1
}

## load tip from filename
proc ::tip-of-the-day::load {filename} {
    set result 0
    if {[catch {set fp [open $filename r]}]} {
        #puts "unable to open $filename"
        return $result
    }
    set title {}
    set detail {}
    set url {}
    set author {}
    set compat 1
    while { [gets $fp data] >= 0 } {
        set id [lindex $data 0]
        set data [string trim [string range $data [string length $id] end]]
        if { "TITLE" eq $id } {
            set title $data
        } elseif { "DETAIL" eq $id } {
            set detail "$detail\n$data"
        } elseif { "URL" eq $id } {
            set url $data
        } elseif { "AUTHOR" eq $id } {
            set author $data
        } elseif { "COMPAT" eq $id } {
            # for now ignore compatibility settings
            # LATER use it to exclude tips if they are for Pd-versions that don't apply
        } else {
            #puts "ignoring unknown ID '$id'"
        }
    }
    close $fp

    set title [string map { \{ \" \} \" } [string trim $title] ]
    set detail [string map { \{ \" \} \" } [string trim $detail] ]

    set image "[file rootname $filename].gif"
    if {! [file exists $image] } {
        set image {}
    }
    set patch "[file rootname $filename].pd"
    if {! [file exists $patch] } {
        set patch {}
    }
    if { $compat && "${title}{$detail}" ne "" } {
        if { [::tip-of-the-day::add_tip $title $detail $author $url $image $patch] } {
            set result 1
        }
    }
    return $result
}

# create an image and assoicate it with a widget
proc ::tip-of-the-day::make_image {winid} {
    variable images
    set newimg [image create photo]
    lappend images($winid) $newimg
    return $newimg
}
# remove all (temporary) images associated with a widget
proc ::tip-of-the-day::free_imageloop {winid} {
    # cancel the running imageloop
    variable imageloop
    if { [info exists imageloop($winid) ] } {
        after cancel $imageloop($winid)
    }

    # free all temporary images
    variable images
    if { [info exists images($winid) ] } {
        foreach img $images($winid) {
            catch {image delete $img}
        }
    }

    # unbind the click-to-repeat
    bind $winid <1> {}

}

# loop through images that are cached in memory
# this is done by simply copying the cached image to the targetimage
proc ::tip-of-the-day::loopImgFromMemory {winid targetimg imagelist {index 0} {time 100}} {
    set img [lindex $imagelist $index]
    set nextIndex [expr ($index + 1) % [llength $imagelist]]
    $targetimg copy $img -compositingrule overlay
    if { $nextIndex != 0 } {
        set ::tip-of-the-day::imageloop($winid) [after $time [list ::tip-of-the-day::loopImgFromMemory $winid $targetimg $imagelist $nextIndex $time]]
    } else {
        #loop stop: should we tell the user to click to restart the animation?
    }
}

proc ::tip-of-the-day::loopAgain {winid targetimg imagelist time} {
    variable imageloop
    if { [info exists imageloop($winid) ] } {
        after cancel $imageloop($winid)
    }
    ::tip-of-the-day::loopImgFromMemory $winid $targetimg $imagelist 0 ${time}
}

# loop through images of a multi-frame GIF
# while the frames are read (and composited to the final frame) they are also cached
# this speeds up looping significantly after the first round
proc ::tip-of-the-day::loopImgFromDisk {winid targetimg fileimg {index 0} {time 100} {imagelist {}}} {
    if { ! [winfo exists $winid]} { return  }
    if {[catch {$fileimg configure -format "gif -index $index"} stderr]} {
        image delete $fileimg
        if { [llength $imagelist] > 1 } {
            bind $winid <1> [list ::tip-of-the-day::loopAgain $winid $targetimg $imagelist ${time}]
        }
    } else {
        $targetimg copy $fileimg -compositingrule overlay

        set newimg [::tip-of-the-day::make_image $winid]
        $newimg configure -height [image height $targetimg] -width [image width $targetimg]
        $newimg copy $targetimg -compositingrule set
        lappend imagelist $newimg

        set ::tip-of-the-day::imageloop($winid) [after ${time} [list ::tip-of-the-day::loopImgFromDisk $winid $targetimg $fileimg [expr {$index + 1}] $time $imagelist]]
    }
}


proc ::tip-of-the-day::get-new-tips {{winid .}} {
    set proto http
    if {[info exists ::deken::protocol] && $::deken::protocol != {} } {
        # maybe we can use http://...
        set proto $::deken::protocol
    }
    set URL ${proto}://deken.puredata.info/tip-of-the-day/tips.zip
    set outdir [::deken::utilities::get_writabledir ${::tip-of-the-day::tipsdirs}]

    if { "${outdir}" eq {} } {
        ::pdwindow::error [_ "None of these tips-of-the-day directories exist or are writable:"]
        ::pdwindow::error "\n"
        foreach d ${::tip-of-the-day::tipsdirs} {
            ::pdwindow::error "\t$d\n"
        }
        return
    }


    set outdir [file normalize $outdir]
    set tmpdir [::deken::utilities::get_tmpdir]
    if { $tmpdir eq {} } { set tmpdir $outdir }
    set outfile [::deken::utilities::get_tmpfilename $tmpdir .zip tips-of-the-day]
    set tipszip [::deken::utilities::download_file $URL $outfile]
    set numtips [llength ${::tip-of-the-day::tips}]

    ::deken::utilities::extract $outdir $tipszip [file normalize $tipszip] 0
    set tipsies 0
    foreach filename [glob -directory $outdir -nocomplain -types {f} -- "*.txt"] {
        if { [::tip-of-the-day::load $filename] } {
            incr tipsies
        }
    }
    if { $tipsies > 0 } {
        ::tip-of-the-day::messageBox $numtips
    } else {
        tk_messageBox \
            -title [_ "Updated Tips of the Day" ] \
            -message [format [_ "%d tips added" ] $tipsies] \
            -type ok \
            -icon info \
            -parent $winid
    }

}


# ######################################################################
# ################ core ################################################
# ######################################################################


## save preferences (whether the user wants automatic tips on startup or not)
proc ::tip-of-the-day::save_prefs {} {
    ::pd_guiprefs::write tipoftheday_startup ${::tip-of-the-day::run_at_startup}
}


# puts the text/images of the given $tipid into $textwin
# ($textwin is a reference to a 'text' widget)
proc ::tip-of-the-day::update_tip_info {textwin {tipid {}}} {
    if { ! [winfo exists $textwin] } {return}

    set numtips [llength ${::tip-of-the-day::tips}]
    if { {} eq $tipid} {
        set tipid ${::tip-of-the-day::current_tip}
    }
    set tipid [expr $tipid % $numtips ]

    foreach {title detail author url image patch} [lindex ${::tip-of-the-day::tips} $tipid] {break}

    $textwin configure -state normal
    $textwin delete 1.0 end

    if { {} ne ${title} } {
        $textwin insert end "${title}" title
        $textwin insert end "\n\n"
    }
    $textwin insert end ${detail}
    $textwin insert end "\n"

    ::tip-of-the-day::free_imageloop $textwin
    if { {} ne ${image} } {
        set fileimg [::tip-of-the-day::make_image $textwin]
        $fileimg configure -file $image
        $textwin.img configure -file [$fileimg cget -file]
        $textwin image create end -image $textwin.img
        $textwin insert end "\n"
        ::tip-of-the-day::loopImgFromDisk $textwin $textwin.img $fileimg
    }


    if { {} ne ${patch} } {
        $textwin tag bind patch <1> [list open_file $patch]
        $textwin insert end "\n"
        $textwin insert end [_ "Try it out!"] patch
        $textwin insert end "\n"
    }

    if { {} ne ${url} } {
        $textwin tag bind url <1> [list pd_menucommands::menu_openfile $url]
        $textwin insert end "\n"
        $textwin insert end [_ "More info..."] url
        $textwin insert end "\n"
    }

    if { {} ne ${author} } {
        $textwin insert end "\n"
        $textwin insert end [format [_ "Suggested by %s"] $author] author
        $textwin insert end "\n"
    }


    $textwin configure -state disabled

    # set the internal counter to the next tip
    set tipid [expr ${tipid} + 1]
    set ::tip-of-the-day::current_tip [expr $tipid % $numtips ]


    # make a nice window title
    set msg [_ "Tip of the Day"]
    wm title [winfo toplevel $textwin] "$msg #${tipid}/${numtips}"
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
    wm geometry $winid 600x450
    wm minsize $winid 230 360
    wm resizable $winid 1 0
    wm transient $winid
    $winid configure -padx 10 -pady 5
    focus $winid
    bell -displayof $winid -nice

    if {$::windowingsystem eq "aqua"} {
        $winid configure -menu $::dialog_menubar
    }


    set msgid $winid.totd.tip

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
    label $bt.update -text "Check online for updated tips" -fg blue -cursor hand2 -anchor e
    pack $bt.update -side top -expand 1 -fill "x" -padx 15 -ipadx 10
    bind $bt.update "<Button-1>" [list ::tip-of-the-day::get-new-tips $winid]

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


    ######################################################
    # show tip
    frame $winid.totd
    pack $winid.totd -side top -fill "both"

    text $msgid -padx 10 -pady 10 -wrap word \
        -yscrollcommand "$winid.totd.scroll set"
    scrollbar $winid.totd.scroll -command "$msgid yview"
    pack $winid.totd.scroll -side right -fill y
    pack $msgid -side right -fill both -expand 1

    pack $msgid

    $msgid tag configure title -font TkCaptionFont
    $msgid tag configure url -foreground blue
    $msgid tag configure patch -foreground blue
    $msgid tag configure author -foreground grey

    $msgid tag bind url <1> "pd_menucommands::menu_openfile https://puredata.info/"
    $msgid tag bind url <Enter> "$msgid tag configure url -underline 1; $msgid configure -cursor $::cursor_runmode_clickme"
    $msgid tag bind url <Leave> "$msgid tag configure url -underline 0; $msgid configure -cursor xterm"
    $msgid tag bind patch <Enter> "$msgid tag configure patch -underline 1; $msgid configure -cursor $::cursor_editmode_nothing"
    $msgid tag bind patch <Leave> "$msgid tag configure patch -underline 0; $msgid configure -cursor xterm"

    image create photo $msgid.img


    ######################################################
    # finalize
    bind $winid <$::modifier-Key-w> "destroy $winid %W; break"
    bind $winid <KeyPress-Escape> "destroy $winid %W; break"

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
    foreach pathdir [list [file join $::current_plugin_loadpath tips] [file join $::sys_libdir doc 7.stuff tips-of-the-day ]] {
        set dir [file normalize $pathdir]
        lappend ::tip-of-the-day::tipsdirs $dir
        if { ! [file isdirectory $dir]} {continue}
        foreach filename [glob -directory $dir -nocomplain -types {f} -- "*.txt"] {
            ::tip-of-the-day::load $filename
        }
    }
    set startup [::pd_guiprefs::read tipoftheday_startup]
    if { [catch {set startup [expr bool($startup) ] } ] } {
        set startup 1
    }
    if { [llength ${::tip-of-the-day::tips}] < 1 } {
        set msg "Update to the latest 'Tips of the Day' via the 'Check online for updated tips' button below."
        ::tip-of-the-day::add_tip "More 'Tips of the Day'" $msg
    }

    set ::tip-of-the-day::run_at_startup $startup
    if { $startup } {
        after idle ::tip-of-the-day::show
    }

}

::tip-of-the-day::initialize
}
