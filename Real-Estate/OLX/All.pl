#!/usr/bin/perl

use lib '/root/Real-Estate/lib';
use strict;

use Database;
use Conf;

use Encode;
use HTML::TreeBuilder;
use WWW::Mechanize;

my $source = 'OLX';

my $db  = Database->new;
my $sth = $db->prepare_replace($source) || exit;

my $conf   = Conf->new;
my $cities = $conf->{city}{$source};

# The below 3 cities don't have their own city-wise URLs. So they should
# be scraped first so that the ads will be come under their own cities.
# Otherwise they will go to other cities. However, these ads will be
# repeated for the next scraps also, but will be skipped by the MySQL
# unique constraint.
my @cities = ('Idukki', 'Pathanamthitta', 'Wayanad');
for my $city (sort keys %$cities) {
    push @cities, $city if ! grep { $_ eq $city } @cities;
}

my $total_count = 0;

city:
for my $city (@cities) {
    my $url  = $cities->{$city};
    my $mech = WWW::Mechanize->new();

    eval { $mech->get($url); };
    if ($@) {
        print "Error connecting to $url. Skipping...\n";
        next city;
    }

    my $tree = HTML::TreeBuilder->new_from_content(decode_utf8($mech->content()));
    my @title_divs = $tree->look_down(_tag => 'h3', class => 'large lheight20 margintop10');
    my @detail_divs = $tree->look_down(_tag => 'p', class => 'color-9 lheight14 margintop3');
    my @price_divs  = $tree->look_down(_tag => 'strong', class => 'c000');
    my @time_divs   = $tree->look_down(_tag => 'p', class => 'color-9 lheight14 margintop3 small');
    print scalar @title_divs . "\n";
    print scalar @detail_divs . "\n";
    print scalar @price_divs . "\n";
    print scalar @time_divs . "\n";
    # exit;

    my $count = 0;
    ad:
    for my $div (@title_divs) {
        my $a        = $div->look_down(_tag => 'a');
        my $link     = $a->attr('href');
        my $title    = $div->as_trimmed_text;

        my $type     = $detail_divs[$count]->as_trimmed_text;
        my $locality = $detail_divs[$count]->look_down(_tag => 'span')->as_trimmed_text;
        $type        =~ s/$locality$//;

        my $price    = $price_divs[$count]->as_trimmed_text;
        my $time     = $time_divs[$count]->as_trimmed_text;

        print "title: $title\n";
        # print "summary: $summary\n";
        print "type: $type\n";
        print "locality: $locality\n";
        print "price: $price\n";
        print "time: $time\n";
        print "link: $link\n";
        # exit;

        $count++;
        print "count: $count\n\n";

        $sth->execute($city, $title, $type, undef, $locality, $price, $time, $link) or next ad;

        $total_count++;
        print "total count: $total_count\n\n";
    }
}