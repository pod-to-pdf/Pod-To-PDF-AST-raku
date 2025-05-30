use v6;

use Test;
use LibXML::Writer::Buffer;
use Pod::To::PDF::XML::Writer;

plan 1;

my $xml = q{<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE Document SYSTEM "http://pdf-raku.github.io/dtd/tagged-pdf.dtd">
<Document Lang="en">
  <P>asdf</P>
  <L>
    <LI>
      <Lbl>•</Lbl>
      <LBody>Abbreviated 1</LBody>
    </LI>
    <LI>
      <Lbl>•</Lbl>
      <LBody>Abbreviated 2</LBody>
    </LI>
  </L>
  <P>asdf</P>
  <L>
    <LI>
      <Lbl>•</Lbl>
      <LBody>
        <P>Top Item</P>
        <L>
          <LI>
            <Lbl>1</Lbl>
            <LBody>First numbered sub-item</LBody>
          </LI>
          <LI>
            <Lbl>2</Lbl>
            <LBody>Second numbered sub-item</LBody>
          </LI>
          <LI>
            <Lbl>◦</Lbl>
            <LBody>Un-numbered sub-item</LBody>
          </LI>
        </L>
      </LBody>
    </LI>
    <LI>
      <Lbl>•</Lbl>
      <LBody>Paragraph item</LBody>
    </LI>
  </L>
  <P>asdf</P>
  <L>
    <LI>
      <Lbl>•</Lbl>
      <LBody>Block item</LBody>
    </LI>
  </L>
  <P>asdf</P>
  <L>
    <LI>
      <Lbl>•</Lbl>
      <LBody>Abbreviated</LBody>
    </LI>
    <LI>
      <Lbl>•</Lbl>
      <LBody>Paragraph item</LBody>
    </LI>
    <LI>
      <Lbl>•</Lbl>
      <LBody>
        <P>Block item</P>
        <P>with multiple</P>
        <P>paragraphs</P>
      </LBody>
    </LI>
  </L>
  <P>asdf</P>
</Document>
};

my LibXML::Writer::Buffer $doc .= new;
my Pod::To::PDF::XML::Writer $writer .= new: :$doc;
$writer.render($=pod);
is $doc.Str, $xml,
   'Various types of items convert correctly';


=begin pod
asdf

=item Abbreviated 1
=item Abbreviated 2

asdf

=begin item1
Top Item
=item2 #  First numbered sub-item
=item2 #  Second numbered sub-item
=item2    Un-numbered sub-item
=end item1

=for item
Paragraph
item

asdf

=begin item
Block
item
=end item

asdf

=item Abbreviated

=for item
Paragraph
item

=begin item
Block
item

with
multiple

paragraphs
=end item

asdf
=end pod
