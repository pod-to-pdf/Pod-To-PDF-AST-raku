use v6;

use Test;
use LibXML::Writer::Buffer;
use Pod::To::PDF::XML::Writer;

plan 1;

my $xml = q{<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE Document SYSTEM "http://pdf-raku.github.io/dtd/tagged-pdf.dtd">
<Document Lang="en">
  <P>asdf</P>
  <Code Placement="Block">indented</Code>
  <P>asdf</P>
  <Code Placement="Block">indented
multi
line</Code>
  <P>asdf</P>
  <Code Placement="Block">indented
multi
line

    nested
and
broken
up</Code>
  <P>asdf</P>
  <Code Placement="Block">Abbreviated
</Code>
  <P>asdf</P>
  <Code Placement="Block">Paragraph
code
</Code>
  <P>asdf</P>
  <Code Placement="Block">Delimited
code
</Code>
  <P>asdf</P>
  <Code Placement="Block"><Strong>Formatted</Strong>
code
</Code>
</Document>
};

my LibXML::Writer::Buffer $doc .= new;
my Pod::To::PDF::XML::Writer $writer .= new: :$doc;
$writer.render($=pod);
'/tmp/out.xml'.IO.spurt: $doc.Str;
is $doc.Str, $xml,
   'Various types of code blocks convert correctly.';

=begin pod
asdf

    indented

asdf

    indented
    multi
    line

asdf

    indented
    multi
    line
    
        nested
    and
    broken
    up

asdf

=code Abbreviated

asdf

=for code
Paragraph
code

asdf

=begin code
Delimited
code
=end code

asdf

=begin code :allow<B>
B<Formatted>
code
=end code

=end pod
