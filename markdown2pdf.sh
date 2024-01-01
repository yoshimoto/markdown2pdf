#!/bin/bash


set -e

msg(){ echo "$@" > /dev/stderr; }
usage(){
    [ -n "$@" ] && (msg $@ ; echo)
    cat <<EOF
 usage:
     $0  [OPTIONS] INPUT-FILENAME

  -o, --output FILENAME
      Filename for output pdf file


  -g, --geometry GEOMETRY
      Page geometry. Supported GEOMETRYs are "tight", "normal". (default "tight")


  --layout LAYOUT
       Page layout. Supported LAYOUTs are:
         - "2x1" (two-up, side-by-side)
         - "1x2"
         - "normal" (default)

  -2
      alias of --layout 2x1 (2-up side-by-side layout)

  --highlight-style STYLE
      Style of syntax highlight. Supported STYLEs are "tango", "haddock", "kate", etc. a
      See pandoc's manual for details.

  --toc
      Generate table of content

  --config FILENAME
      Filename for configration. (default: ~/.markdown2pdf)
EOF
    exit 1
}
error(){ msg $@; exit 1; }

# Parse command line arguments
#
unset OUTPUT
unset INPUT

NumPerPage=1
highlightstyle="tango"
geometry="tight"
layout="normal"
unset enabletoc

configfile=${HOME}/.markdown2pdf

# Save command-line args
CMDARGS="$@"

# Parse command-line (1st stage)
while [ $# -ne 0 ]; do
    case "$1" in
	--config)
	    configfile="$2"
	    [ -f "$configfile" ] || error "No such config file, $configfile"
	    shift
	    ;;
    esac
    shift
done

[ -f "$configfile" ] && source "$configfile"


# Parse command-line (2nd stage)
# Restore command-line args
set -- $CMDARGS
while [ $# -ne 0 ]; do
    case "$1" in
	--config)
	    shift
	    ;;
	-o|--output)
	    OUTPUT="$2"
	    shift
	    ;;
	-g|--geometry)
	    geometry="$2"
	    shift
	    ;;
	--layout)
	    layout="$2"
	    shift
	    ;;
	-2)
	    layout="2x1"
	    ;;
	--highlight-style)
	    highlightstyle="$2"
	    shift
	    ;;
	--help|-h)
	    usage
	    ;;
	--toc)
	    enabletoc=1
	    ;;
	-*)
	    usage "Error; bad option '$1' detected"
	    ;;
	*)
	    [ -n "$INPUT" ] && error "Error; too many arguments."
	    INPUT="$1"
	    ;;
    esac
    shift
done


[ -n "$INPUT" ] || usage
if [ -z "$OUTPUT" ]; then
    tmp=${INPUT/.txt/}
    tmp=${tmp/.md/}
    OUTPUT=${tmp}.pdf
    unset tmp
fi


REQS="pandoc"
for exe in $REQS; do
    type $exe > /dev/null 2>&1
    if [ $? -ne 0 ]; then
	msg "$exe is not installed. "
	msg "You may use a package manager to install it, as follows:"
	msg " sudo apt install $exe  (debian, ubuntu)"
	msg " sudo dnf install $exe  (redhat, fedora, centos)"
	msg " sudo port install $exe (macport)"
	exit 1
    fi
done

REQS="pdfjam lualatex"
for exe in $REQS; do
    type $exe > /dev/null 2>&1
    if [ $? -ne 0 ]; then
	msg "$exe is not installed. "
	msg "You may use a package manager to install it, as follows:"
	msg " sudo tlmgr install $exe  (TeXLive)"
	msg " sudo apt install $exe  (debian, ubuntu)"
	msg " sudo dnf install $exe  (redhat, fedora, centos)"
	msg " sudo port install $exe (macport)"
	exit 1
    fi
done


TMPDIR=${TMPDIR=/tmp}


TMPFILTER=`mktemp $TMPDIR/filter-XXXXXXX.lua`

cat<<EOF > $TMPFILTER
function raw_tex (t)
  return pandoc.RawBlock('tex', t)
end

--- Wrap code blocks in tcolorbox environments
function CodeBlock (cb)
  return {raw_tex'\\\\begin{tcolorbox}', cb, raw_tex '\\\\end{tcolorbox}'}
end

--- Ensure that the longfbox package is loaded.
function Meta (m)
  m['header-includes'] = {raw_tex '\\\\usepackage{tcolorbox}'}
  return m
end
EOF


OPTS=""
if [ -n "$luatexjapresetoptions" ]; then
    OPTS+=" -V luatexjapresetoptions=$luatexjapresetoptions"
fi

OPTS+=" -V colorlinks=true -V linkcolor=blue  -V urlcolor=red -V toccolor=gray "

if [ -n "$enabletoc" ]; then
    OPTS+=" --table-of-contents "
fi

case "$geometry" in
    tight)
	OPTS+=" -V geometry:margin=2cm -V geometry:top=1.5cm -V geometry:bottom=1.5cm "
	;;
    normal)
	;;
    *)
	error "Bad arguments."
	;;
esac

TMPFILE=`mktemp $TMPDIR/tmp-XXXXXXX.pdf`

pandoc -f markdown \
       --pdf-engine=lualatex \
       -V documentclass=ltjsarticle -V classoption=pandoc  \
       --highlight-style=$highlightstyle \
       --lua-filter $TMPFILTER \
       $OPTS \
       -o $TMPFILE $INPUT

case "$layout" in
    2x1)
	pdfjam --nup 2x1 --landscape $TMPFILE  --outfile $OUTPUT
	;;
    1x2)
	pdfjam --nup 1x2 $TMPFILE  --outfile $OUTPUT
	;;
    normal)
	cp $TMPFILE $OUTPUT
	;;
    *)
	error "Internal error"
	;;
esac

rm $TMPFILE
rm $TMPFILTER

echo
echo
echo "Finished. Output was writtern to '$OUTPUT'."
exit 0
