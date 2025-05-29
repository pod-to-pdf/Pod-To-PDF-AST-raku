TITLE
=====

Pod::To::PDF::XML

SUBTITLE
========

Render Pod as PDF (Experimental)

Description
-----------

Renders Pod to an intermediate XML format for PDF rendering

Usage
-----

From command line:

    $ raku --doc=PDF::XML lib/to/class.rakumod | xml2pdf.raku

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

