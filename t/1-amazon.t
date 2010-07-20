#!/usr/bin/perl -w
use strict;

use Test::More tests => 7;
use 5.006;

BEGIN { use_ok('Music::Tag') }

my $tag = Music::Tag->new( undef,
                           {  artist    => "Sarah Slean",
                              album     => "Orphan Music",
                              title     => "Mary",
                              ANSIColor => 0,
                              quiet     => 1,
                              locale    => "ca"
                           },
                           "Option"
                         );

ok( $tag,                       'Object created' );
ok( $tag->add_plugin("Amazon"), "Plugin Added" );
ok( $tag->get_tag,              'get_tag called' );
is( $tag->asin,  "B000JBWXEQ", 'ASIN Set' );
ok( $tag->upc,  'UPC Set' );
is( $tag->track, 4,            'Track Set' );

