#!/usr/bin/perl

use strict;

use Encode;
use HTML::TreeBuilder;
use WWW::Mechanize;

my $base_url   = 'http://www.99acres.com';
my $search_url = 'http://www.99acres.com/property-in-kochi-ffid';

my $mech = WWW::Mechanize->new();
$mech->agent_alias('Linux Mozilla');

eval { $mech->get($search_url); };
if ($@) {
    print "Error connecting to $search_url. $@ Exitting...\n";
    exit;
}

my $tree = HTML::TreeBuilder->new_from_content(decode_utf8($mech->content()));

my @divs      = $tree->look_down(_tag => 'div', class => 'wrapttl');
my @desc_divs = $tree->look_down(_tag => 'div', class => 'lf  f12');
my @time_divs = $tree->look_down(_tag => 'div', class => 'rf f11 mt25');
#print scalar @divs . "\n";
#print scalar @desc_divs . "\n";
#print scalar @time_divs . "\n";
#exit;

my $count = 0;
for my $div (@divs) {
    my @b       = $div->look_down(_tag => 'b');
    my $price   = $b[1]->as_trimmed_text;
    my ($title, $locality) = $div->look_down(_tag => 'a')->as_trimmed_text =~ m/(.+) in (.+)/;
    my $summary = $desc_divs[$count]->as_trimmed_text;
    $summary    =~ s/^Description : //;
    my $link    = $base_url . $div->look_down(_tag => 'a')->attr('href');
    my $time    = $time_divs[$count]->as_trimmed_text;
    $time       =~ s/^Posted : //;
    #my @a       = $div->look_down(_tag => 'a', class => 'defultchi2');
    #my $type    = $a[0]->as_trimmed_text;

    print "title: $title\n";
    print "summary: $summary\n";
    #print "type: $type\n";
    print "locality: $locality\n";
    print "price: $price\n";
    print "time: $time\n";
    print "link: $link\n";
    exit;

    $count++;
    print "count: $count\n\n";
}

sub trim {
    my $string = shift;
    $string =~ s/^\s+|\s+$//g;
    return $string;
}