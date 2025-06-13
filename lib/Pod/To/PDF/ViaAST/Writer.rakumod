unit class Pod::To::PDF::ViaAST::Writer;

use PDF::API6;
use PDF::Page;
has PDF::API6:D $.pdf is required;
has PDF::Page $!page;
has PDF::Content $!gfx;

submethod TWEAK {
    $!page = $!pdf.add-page;
    $!gfx = $!page.gfx;
}

multi method ast2pdf(Pair $node) {
    my Str:D $tag = $node.key;
    $!gfx.tag: $tag, {
        self.ast2pdf: |$node;
    }
}

multi method ast2pdf(:Document(@args)!) {
    $!gfx.say: "todo Document => {@args.raku}", :width(500), :position[10, 700];
}

multi method ast2pdf(*%args) {
    die "todo " ~ %args.raku;
}
