use v6;

use Test;
use LibXML::Writer::Buffer;
use PDF::Render::Tree::From::Pod;

plan 1;

my $xml = q{<Document Lang="en">
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
</Document>};

my LibXML::Writer::Buffer $doc .= new;
my PDF::Render::Tree::From::Pod $reader .= new: :indent;
$doc.write: $reader.render($=pod);
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
