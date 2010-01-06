#!/bin/sh
# install-after.sh -- Custom installation steps
#
# The script will receive one argument: relative path to
# installation root directory. Script is called like:
#
#    $ ./install-after.sh .inst/
#
# This script is used to things after the [install] command.

Cmd()
{
    echo "$@"
    [ "$test" ] && return
    "$@"
}

Relocate ()
{
    echo ">> Relocate etc/joe/doc"

    dir=$root/etc/joe/doc

    if [ -d $dir ] ; then
	Cmd mv $root/etc/joe/doc/* $root/usr/share/doc/joe-*/
	Cmd rmdir $dir
    fi

    echo ">> Relocate etc/joe/*rc"
    docdir=$(cd $root/usr/share/doc/joe-*/ && pwd)
    exdir=$docdir/examples
    dir=$root/etc/joe

    if [ -d $dir ] && [ "$docdir" ] ; then
	Cmd install -d -m 755 $exdir
	Cmd mv $dir/* $exdir/
    fi
}

Delete ()
{
    # See joe.README, why this file is removed

    list=$(find $root -name termidx.exe)
    [ "$list" ] && Cmd rm --verbose $list
}

Main()
{
    root=${1:-".inst"}

    if [ "$root"  ] && [ -d $root ]; then

        root=$(echo $root | sed 's,/$,,')  # Delete trailing slash

	Delete
    fi
}

Main "$@"

# End of file
