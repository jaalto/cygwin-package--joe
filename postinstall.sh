#!/bin/sh
# Copyright (C) 2007-2008 Jari Aalto; Licenced under GPL v2 or later
#
# /etc/postinstall/<package>.sh -- Custom installation steps
#
# -- NOTE: This script will be run under /bin/sh
# -- THIS AN EXAMPLE, MODIFY AS NEEDED
#

PATH="/bin:/usr/bin:/sbin:/usr/sbin:/usr/X11R6/bin:$PATH"

package="joe"

Environment()
{
    #  Define variables for the rest of the script

    [ "$1" ] && dest="$1"        # install destination

    if [ "$dest" ]; then
        #  Delete trailing slash
        dest=$(echo $dest | sed -e 's,/$,,' )
    fi

    #   This file will be installed as
    #   /etc/postinstall/<package>.sh so derive <package>
    #   But if this file is run from CYGIN-PATCHES/postinstall.sh
    #   then we do not know the package name

    name=$(echo $0 | sed -e 's,.*/,,' -e 's,\.sh,,' )

    if [ "$name" != "postinstall" ]; then
        package="$name"
    fi

    bindir="$dest/usr/bin"
    libdir="$dest/usr/lib"
    libdirx11="$dest/usr/lib/X11"
    includedir="$dest/usr/include"

    sharedir="$dest/usr/share"
    infodir="$sharedir/info"
    docdir="$sharedir/doc"
    etcdir="$dest/etc"

    #   1) list of files to be copied to /etc
    #   2) Source locations

    defaultsdir=$dest/etc/defaults/etc/$package
    manifestdir=$etcdir/postinstall
    conffile="$manifestdir/$package-manifest.lst"
}

Warn ()
{
    echo "$*" >&2
}

Run ()
{
    echo "$@"
    [ "$test" ] || "$@"
}

InstallConffiles ()
{
    [ ! -f "$conffile" ] && return

    #  Install default configuration files for system wide

    latest=$(LC_ALL=C find /usr/share/doc/$package*/ \
               -maxdepth 0 -type d \
             | sort | tail -1 | sed 's,/$,,')

    if [ ! "$latest" ]; then
        Warn "$0: [FATAL] Cannot find $package install doc dir"
        exit 1
    fi

    tmpprefix="${TEMPDIR:-/tmp}/tmp$$"
    clean="$tmpprefix.to"

    #  Filter out all comments. Grep only lines with filenames

    grep -E '^[^#]*/|^[[:space]]*$' $conffile > $clean

    while read from to
    do
        #  Both of these are are normally full file paths.
        #  - Translate few special "variables"
        #  - if TO is plain directory (ending to slash), reuse
        #    filename from FROM part.

        from=$(echo $dest$from | sed "s,\$PKGDOCDIR,$pkgdocdir$latest," )
        to=$(echo $dest$to | sed "s,\$PKG,$pkgdocdir," )

        [ ! "$from" ] && continue                       # empty line

        if [ ! "$to" ] ; then
            Warn "$conffile: [ERROR] in line: $from"
            continue
        fi

        if [ -d "$to" ] || echo $to | grep "/$" > /dev/null; then
            to=$(echo $to | sed 's,/$,,')
            to=$to/$(basename $from)
        fi

        #  Install only if a) not already there b) not changed

        name=$(basename $to)
        default=$defaultsdir/$name

        if [ ! -f "$to" ]; then
            Run install -m 0644 $from $to

        elif [ -f "$to" ] && [ ! -f "$default" ] ; then
                Warn "$0: [WARN] $to exists, no default"

        elif [ -f "$to" ] && [ -f "$from" ] ; then

            if cmp --quiet $default $to            # Same. No user changes
            then
                if ! cmp --quiet $from $default    # Not same. conf changes
                then
                    Run install -D -m 0644 $from $to
                fi
            else
                Warn "$0: [WARN] $to has changed." \
                     "Not installing new $from"
            fi
        fi

        #  Install new default from this package so that next install
        #  can compare if the file has stayed the same.

        Run install -D -m 0644 $from $default

    done < "$clean"

    rm -f "$clean"
}

Main()
{
    Environment "$@"    &&
    InstallConffiles
}

Main "$@"

# End of file
