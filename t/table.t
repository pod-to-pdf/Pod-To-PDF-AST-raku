use v6;

use Test;
use LibXML::Writer::Buffer;
use PDF::Render::Tree::From::Pod;
plan 1;

my $xml = q{<Document lang="en">
  <P>asdf</P>
  <Table>
    <Caption>Table 1</Caption>
    <TBody>
      <TR>
        <TD>A A</TD>
        <TD>B B</TD>
        <TD>C C</TD>
      </TR>
      <TR>
        <TD>1 1</TD>
        <TD>2 2</TD>
        <TD>3 3</TD>
      </TR>
    </TBody>
  </Table>
  <P>asdf</P>
  <Table>
    <Caption>Table 2</Caption>
    <THead>
      <TR>
        <TH>H 1</TH>
        <TH>H 2</TH>
        <TH>H 3</TH>
      </TR>
    </THead>
    <TBody>
      <TR>
        <TD>A A</TD>
        <TD>B B</TD>
        <TD>C C</TD>
      </TR>
      <TR>
        <TD>1 1</TD>
        <TD>2 2</TD>
        <TD>3 3</TD>
      </TR>
    </TBody>
  </Table>
  <P>asdf</P>
  <Table>
    <Caption>Table 3</Caption>
    <THead>
      <TR>
        <TH>H11</TH>
        <TH>HHH 222</TH>
        <TH>H 3</TH>
      </TR>
    </THead>
    <TBody>
      <TR>
        <TD>AAA</TD>
        <TD>BB</TD>
        <TD>C C C C</TD>
      </TR>
      <TR>
        <TD>1 1</TD>
        <TD>2 2 2 2</TD>
        <TD>3 3</TD>
      </TR>
    </TBody>
  </Table>
  <P>asdf</P>
  <Table>
    <THead>
      <TR>
        <TH>H 1</TH>
        <TH>H 2</TH>
        <TH>H 3</TH>
        <TH>H 4</TH>
      </TR>
    </THead>
    <TBody>
      <TR>
        <TD>Hello, I'm kinda long, I think</TD>
        <TD>B B</TD>
        <TD>C C</TD>
        <TD></TD>
      </TR>
      <TR>
        <TD>1 1</TD>
        <TD>Me also, methinks</TD>
        <TD>3 3</TD>
        <TD>This should definitely wrap. Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt</TD>
      </TR>
      <TR>
        <TD>ww</TD>
        <TD>xx</TD>
        <TD>yy</TD>
        <TD>zz</TD>
      </TR>
    </TBody>
  </Table>
  <P>asdf</P>
</Document>};

my LibXML::Writer::Buffer $doc .= new;
my PDF::Render::Tree::From::Pod $reader .= new: :indent;
$doc.write: $reader.render($=pod);
is $doc.Str, $xml,
    'Converts tables correctly';

=begin pod
asdf
=begin table :caption('Table 1')
A A    B B       C C
1 1    2 2       3 3
=end table
asdf
=begin table :caption('Table 2')
H 1 | H 2 | H 3
====|=====|====
A A | B B | C C
1 1 | 2 2 | 3 3
=end table
asdf

=begin table :caption('Table 3')
       HHH
  H11  222  H 3
  ===  ===  ===
  AAA  BB   C C
            C C

  1 1  2 2  3 3
       2 2
=end table
asdf

=begin table
H 1 | H 2 | H 3 | H 4
====|=====|=====|====
Hello, I'm kinda long, I think | B B | C C
1 1 | Me also, methinks | 3 3 | This should definitely wrap. Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt
ww | xx | yy | zz
=end table
asdf

=end pod
