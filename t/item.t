use v6;

use Test;
use LibXML::Writer::Buffer;
use Pod::To::PdfAST;

plan 1;

my $xml = q{<Document Lang="en">
  <P>asdf</P>
  <L>
    <LI>
      <LBody>
        <P>Abbreviated 1</P>
      </LBody>
    </LI>
    <LI>
      <LBody>
        <P>Abbreviated 2</P>
      </LBody>
    </LI>
  </L>
  <P>asdf</P>
  <L>
    <LI>
      <LBody>
        <P>Top Item</P>
        <L>
          <LI>
            <Lbl>1</Lbl>
            <LBody>
              <P>First numbered sub-item</P>
            </LBody>
          </LI>
          <LI>
            <Lbl>2</Lbl>
            <LBody>
              <P>Second numbered sub-item</P>
            </LBody>
          </LI>
          <LI>
            <LBody>
              <P>Un-numbered sub-item</P>
            </LBody>
          </LI>
        </L>
      </LBody>
    </LI>
    <LI>
      <LBody>
        <P>Paragraph item</P>
      </LBody>
    </LI>
  </L>
  <P>asdf</P>
  <L>
    <LI>
      <LBody>
        <P>Block item</P>
      </LBody>
    </LI>
  </L>
  <P>asdf</P>
  <L>
    <LI>
      <LBody>
        <P>Abbreviated</P>
      </LBody>
    </LI>
    <LI>
      <LBody>
        <P>Paragraph item</P>
      </LBody>
    </LI>
    <LI>
      <LBody>
        <P>Block item</P>
        <P>with multiple</P>
        <P>paragraphs</P>
      </LBody>
    </LI>
  </L>
  <P>asdf</P>
</Document>};

my LibXML::Writer::Buffer $doc .= new;
my Pod::To::PdfAST $writer .= new: :indent;
$doc.write: $writer.render($=pod);
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
