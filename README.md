TITLE
=====

Pod::To::XML

SUBTITLE
========

Render Pod as PDF (Experimental)

Description
-----------

Renders Pod to an intermediate XML format

Usage
-----

From command line:

    $ raku --doc=PDF::XML lib/to/class.rakumod | xml2pdf.raku

From Raku:

```raku
use Pod::To::XML;
use PDF::API6;

=NAME foobar.pl
=Name foobar.pl

=Synopsis
    foobar.pl <options> files ...

my $xml = pod2xml($=pod);
"foobar.xml".IO.spurt: $xml;
```
Exports
-------

    class Pod::To::XML;
    sub pod2pdf; # See below

Subroutines
-----------

### sub pod2pdf()

```raku sub pod2pdf( Pod::Block $pod ) returns Str;```

