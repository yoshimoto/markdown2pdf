# markdown2pdf.sh

Convert your markdown file to PDF


# Usage

~~~~sh
$ markdown2pdf.sh  your-markdown-file  --output output.pdf
~~~~

# Option

~~~~sh
$ markdown2pdf.sh --help
~~~~

~~~~
 usage:
     $0  [OPTIONS] INPUT

  -o, --output FILENAME
      The filename for output pdf file

  -g, --geometry mode
      Page layout. Supported MODEs are "tight", "normal". (default: "tight")

  -2
      2-up side-by-side layout

  --highlightstyle STYLE
      Style of syntax highlight. Supported STYLEs are "tango", "haddock", "kate", etc.
	  See pandoc's manual for details.
~~~~
