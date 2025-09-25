TITLE
=====

Pod::To::XML

SUBTITLE
========

Output a PDF Rendering tree as XML or HTML

Description
-----------

Outputs an intermediate PDF::Render::Tree AST as XML, or with a lightweight
transform to HTML.

Usage
-----

From command line:

    $ raku --doc=XML lib/to/class.rakumod | ast2pdf.raku
    $ raku --doc=XML lib/to/class.rakumod --save-as=class.html | ast2pdf.raku

From Raku:

```raku
use Pod::To::XML;

=NAME foobar.pl
=Name foobar.pl

=Synopsis
    foobar.pl <options> files ...

my $xml = pod2pdf-xml($=pod);
"foobar.xml".IO.spurt: $xml;
```
Exports
-------

    class Pod::To::XML;
    sub pod2pdf-xml; # See below

Subroutines
-----------

### sub pod2pdf-xml()

```raku sub pod2pdf-xml( Pod::Block $pod ) returns Str;```

