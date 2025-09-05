use v6;

use Test;
use LibXML::Writer::Buffer;
use Pod::To::XML;

plan 2;

my $xml = q{<?xml version="1.0" encoding="UTF-8"?>
<Document Lang="en">
  <L role="DL">
    <LI role="DL-DIV">
      <Lbl Placement="Block" role="DT">Happy</Lbl>
      <LBody role="DD">
        <P>When you're not blue.</P>
      </LBody>
    </LI>
    <LI role="DL-DIV">
      <Lbl Placement="Block" role="DT">Blue</Lbl>
      <LBody role="DD">
        <P>When you're not happy.</P>
      </LBody>
    </LI>
  </L>
</Document>
};

my $html = q{<html>
<head><meta http-equiv="Content-Type" content="text/html; charset=UTF-8"></head>
<body><dl>
<dt>Happy</dt>
<dd><P>When you're not blue.</P></dd>
<dt>Blue</dt>
<dd><P>When you're not happy.</P></dd>
</dl></body>
</html>
};

given Pod::To::XML::render($=pod) {
    .&is: $xml, 'Definitions convert to XML correctly.';
}

given Pod::To::XML::render($=pod, :format<html>) {
    .&is: $html, 'Definitions convert to HTML correctly.';
}

=begin pod

=defn # Happy
When you're not blue.

=defn # Blue
When you're not happy.

=end pod
