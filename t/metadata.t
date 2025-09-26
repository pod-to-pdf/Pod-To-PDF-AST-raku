use v6;

use Test;
use LibXML::Writer::Buffer;
use PDF::Render::Tree::From::Pod;

plan 1;

my $xml = q{<Document Author="David Warring" Subject="Subtitle from POD" Title="Main Title v1.2.3" Lang="en">
  <Title>Main Title</Title>
  <H2>Subtitle from POD</H2>
  <H2>Author</H2>
  <P>David Warring</P>
  <H2>Version</H2>
  <P>1.2.3</P>
  <H2>Head2 from POD</H2>
  <P>a paragraph.</P>
</Document>};

my LibXML::Writer::Buffer $doc .= new;
my %replace = :where<POD>;
my PDF::Render::Tree::From::Pod $reader .= new: :indent, :%replace;
$doc.write: $reader.render($=pod);
is $doc.Str, $xml,
   'Various types of metadata convert correctly';

=begin pod
=TITLE Main Title
=SUBTITLE Subtitle from R<where>
=AUTHOR David Warring
=VERSION 1.2.3

=head2 Head2 from R<where>

a paragraph.
=end pod

