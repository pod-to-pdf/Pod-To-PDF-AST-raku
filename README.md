TITLE
=====

Pod::To::PDF::XML

SUBTITLE
========

Convert Pod to PdfXML, or PdfAST (Experimental)

Description
-----------

Renders Pod to a formats for PdfAST rendering

Usage
-----

From command line:

    $ raku --doc=PdfAST lib/to/class.rakumod | ast2pdf.raku

From Raku:

```raku
use Pod::To::PDF::XML;

=NAME foobar.pl
=Name foobar.pl

=Synopsis
    foobar.pl <options> files ...

my $xml = pod2pdf-xml($=pod);
"foobar.xml".IO.spurt: $xml;
```
Exports
-------

    class Pod::To::PDF::XML;
    sub pod2pdf-xml; # See below

Subroutines
-----------

### sub pod2pdf-xml()

```raku sub pod2pdf-xml( Pod::Block $pod ) returns Str;```

