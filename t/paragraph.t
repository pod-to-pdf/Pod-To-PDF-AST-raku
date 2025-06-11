use v6;

use Test;
use LibXML::Writer::Buffer;
use Pod::To::PDF::XML::Writer;

plan 1;

my $xml = q{<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE Document SYSTEM "http://pdf-raku.github.io/dtd/tagged-pdf.dtd">
<Document Lang="en">
  <P>This is all a paragraph.</P>
  <P>This is the next paragraph.</P>
  <P>This is the third paragraph.</P>
  <P>Abbreviated paragraph</P>
  <P>Paragraph paragraph</P>
  <P>Block</P>
  <P>paragraph</P>
  <P>spaces and tabs are ignored</P>
  <P>Paragraph with <Strong>formatting</Strong>, <Code>code</Code> and <Reference><Link href="#blah">links</Link></Reference>.</P>
  <P>Paragraph with (see: <Link href="file:included.pod">file:included.pod</Link>) placement</P>
  <!-- a single word that exceeds the line width -->
  <P>aaaaabbbbbcccccdddddeeeeefffffggggghhhhhiiiiijjjjjkkkkklllllmmmmmnnnnnooooopppppqqqqqrrrrrssssstttttuuuuuvvvvvwwwwwxxxxxyyyyyzzzzz</P>
</Document>
};

my LibXML::Writer::Buffer $doc .= new;
my Pod::To::PDF::XML::Writer $writer .= new;
$doc.write: $writer.render($=pod);
is $doc.Str, $xml;

=begin pod
This is all
a paragraph.

This is the
next paragraph.

This is the
third paragraph.
=end pod

=para Abbreviated paragraph

=for para
Paragraph
paragraph

=begin para
Block

paragraph
=end para

=para spaces  and	tabs are ignored

=para Paragraph with B<formatting>, C<code> and L<links|#blah>.

=para Paragraph with P<file:included.pod> placement

=comment a single word that exceeds the line width

=para aaaaabbbbbcccccdddddeeeeefffffggggghhhhhiiiiijjjjjkkkkklllllmmmmmnnnnnooooopppppqqqqqrrrrrssssstttttuuuuuvvvvvwwwwwxxxxxyyyyyzzzzz
