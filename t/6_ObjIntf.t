# $Id: 6_ObjIntf.t,v 1.4 2002/10/16 09:43:35 grantm Exp $
# vim: syntax=perl

use strict;
use Test::More tests => 27;

##############################################################################
# Derived version of XML::Simple that returns everything in upper case
##############################################################################

package XML::Simple::UC;

use vars qw(@ISA);
@ISA = qw(XML::Simple);

sub build_tree {
  my $self = shift;

  my $tree = $self->SUPER::build_tree(@_);

  ($tree) = uctree($tree);

  return($tree);
}

sub uctree {
  foreach my $i (0..$#_) {
    my $x = $_[$i];
    if(ref($x) eq 'ARRAY') {
      $_[$i] = [ uctree(@$x) ];
    }
    elsif(ref($x) eq 'HASH') {
      $_[$i] = { uctree(%$x) };
    }
    else {
      $_[$i] = uc($x);
    }
  }
  return(@_);
}


##############################################################################
# Derived version of XML::Simple that uses CDATA sections for escaping
##############################################################################

package XML::Simple::CDE;

use vars qw(@ISA);
@ISA = qw(XML::Simple);

sub escape_value {
  my $self = shift;

  my($data) = @_;

  if($data =~ /[&<>"]/) {
    $data = '<![CDATA[' . $data . ']]>';
  }

  return($data);
}


##############################################################################
# Start of the test script itself
##############################################################################

package main;

use XML::Simple;

my $xml = q(<cddatabase>
  <disc id="9362-45055-2" cddbid="960b750c">
    <artist>R.E.M.</artist>
    <album>Automatic For The People</album>
    <track number="1">Drive</track>
    <track number="2">Try Not To Breathe</track>
    <track number="3">The Sidewinder Sleeps Tonite</track>
    <track number="4">Everybody Hurts</track>
    <track number="5">New Orleans Instrumental No. 1</track>
    <track number="6">Sweetness Follows</track>
    <track number="7">Monty Got A Raw Deal</track>
    <track number="8">Ignoreland</track>
    <track number="9">Star Me Kitten</track>
    <track number="10">Man On The Moon</track>
    <track number="11">Nightswimming</track>
    <track number="12">Find The River</track>
  </disc>
</cddatabase>
);

my %opts1 = (
  keyattr => { disc => 'cddbid', track => 'number' },
  keeproot => 1, 
  contentkey => 'title',
  forcearray => [ qw(disc album) ] 
);

my %opts2 = (
  keyattr => { }
);

my $xs1 = new XML::Simple( %opts1 );
my $xs2 = new XML::Simple( %opts2 );
isa_ok($xs1, 'XML::Simple', 'object one');
isa_ok($xs2, 'XML::Simple', 'object two');
is_deeply(\%opts1, {
  keyattr => { disc => 'cddbid', track => 'number' },
  keeproot => 1, 
  contentkey => 'title',
  forcearray => [ qw(disc album) ] 
}, 'options hash was not corrupted');

my $exp1 = {
  'cddatabase' => {
    'disc' => {
      '960b750c' => {
        'id' => '9362-45055-2',
        'album' => [ 'Automatic For The People' ],
        'artist' => 'R.E.M.',
        'track' => {
          1  => { 'title' => 'Drive' },
          2  => { 'title' => 'Try Not To Breathe' },
          3  => { 'title' => 'The Sidewinder Sleeps Tonite' },
          4  => { 'title' => 'Everybody Hurts' },
          5  => { 'title' => 'New Orleans Instrumental No. 1' },
          6  => { 'title' => 'Sweetness Follows' },
          7  => { 'title' => 'Monty Got A Raw Deal' },
          8  => { 'title' => 'Ignoreland' },
          9  => { 'title' => 'Star Me Kitten' },
          10 => { 'title' => 'Man On The Moon' },
          11 => { 'title' => 'Nightswimming' },
          12 => { 'title' => 'Find The River' }
        }
      }
    }
  }
};

my $ref1 = $xs1->XMLin($xml);
is_deeply($ref1, $exp1, 'parsed expected data via object 1');


# Try using the other object

my $exp2 = {
  'disc' => {
    'album' => 'Automatic For The People',
    'artist' => 'R.E.M.',
    'cddbid' => '960b750c',
    'id' => '9362-45055-2',
    'track' => [
      { 'number' => 1,  'content' => 'Drive' },
      { 'number' => 2,  'content' => 'Try Not To Breathe' },
      { 'number' => 3,  'content' => 'The Sidewinder Sleeps Tonite' },
      { 'number' => 4,  'content' => 'Everybody Hurts' },
      { 'number' => 5,  'content' => 'New Orleans Instrumental No. 1' },
      { 'number' => 6,  'content' => 'Sweetness Follows' },
      { 'number' => 7,  'content' => 'Monty Got A Raw Deal' },
      { 'number' => 8,  'content' => 'Ignoreland' },
      { 'number' => 9,  'content' => 'Star Me Kitten' },
      { 'number' => 10, 'content' => 'Man On The Moon' },
      { 'number' => 11, 'content' => 'Nightswimming' },
      { 'number' => 12, 'content' => 'Find The River' }
    ]
  }
};

my $ref2 = $xs2->XMLin($xml);
is_deeply($ref2, $exp2, 'parsed expected data via object 2');


# Confirm default options in object merge correctly with options as args

$ref1 = $xs1->XMLin($xml, keyattr => [], forcearray => 0);

is_deeply($ref1, {              # Parsed to what we expected
  'cddatabase' => {
    'disc' => {
      'album' => 'Automatic For The People',
      'id' => '9362-45055-2',
      'artist' => 'R.E.M.',
      'cddbid' => '960b750c',
      'track' => [
        { 'number' => 1,  'title' => 'Drive' },
        { 'number' => 2,  'title' => 'Try Not To Breathe' },
        { 'number' => 3,  'title' => 'The Sidewinder Sleeps Tonite' },
        { 'number' => 4,  'title' => 'Everybody Hurts' },
        { 'number' => 5,  'title' => 'New Orleans Instrumental No. 1' },
        { 'number' => 6,  'title' => 'Sweetness Follows' },
        { 'number' => 7,  'title' => 'Monty Got A Raw Deal' },
        { 'number' => 8,  'title' => 'Ignoreland' },
        { 'number' => 9,  'title' => 'Star Me Kitten' },
        { 'number' => 10, 'title' => 'Man On The Moon' },
        { 'number' => 11, 'title' => 'Nightswimming' },
        { 'number' => 12, 'title' => 'Find The River' }
      ]
    }
  }
}, 'successfully merged options');


# Confirm that default options in object still work as expected

$ref1 = $xs1->XMLin($xml);
is_deeply($ref1, $exp1, 'defaults were not affected by merge');


# Confirm they work for output too

$_ = $xs1->XMLout($ref1);

ok(s{<track number="1">Drive</track>}                         {<NEST/>}, 't1');
ok(s{<track number="2">Try Not To Breathe</track>}            {<NEST/>}, 't2');
ok(s{<track number="3">The Sidewinder Sleeps Tonite</track>}  {<NEST/>}, 't3');
ok(s{<track number="4">Everybody Hurts</track>}               {<NEST/>}, 't4');
ok(s{<track number="5">New Orleans Instrumental No. 1</track>}{<NEST/>}, 't5');
ok(s{<track number="6">Sweetness Follows</track>}             {<NEST/>}, 't6');
ok(s{<track number="7">Monty Got A Raw Deal</track>}          {<NEST/>}, 't7');
ok(s{<track number="8">Ignoreland</track>}                    {<NEST/>}, 't8');
ok(s{<track number="9">Star Me Kitten</track>}                {<NEST/>}, 't9');
ok(s{<track number="10">Man On The Moon</track>}              {<NEST/>}, 't10');
ok(s{<track number="11">Nightswimming</track>}                {<NEST/>}, 't11');
ok(s{<track number="12">Find The River</track>}               {<NEST/>}, 't12');
ok(s{<album>Automatic For The People</album>}                 {<NEST/>}, 'ttl');
ok(s{cddbid="960b750c"}{ATTR}, 'cddbid');
ok(s{id="9362-45055-2"}{ATTR}, 'id');
ok(s{artist="R.E.M."}  {ATTR}, 'artist');
ok(s{<disc(\s+ATTR){3}\s*>(\s*<NEST/>){13}\s*</disc>}{<DISC/>}s, 'disc');
ok(m{^\s*<(cddatabase)>\s*<DISC/>\s*</\1>\s*$}, 'database');


# Check that overriding build_tree() method works

$xml = q(<opt>
  <server>
    <name>Apollo</name>
    <address>10 Downing Street</address>
  </server>
</opt>
);

my $xsp = new XML::Simple::UC();
$ref1 = $xsp->XMLin($xml);
is_deeply($ref1, {
  'SERVER' => {
    'NAME' => 'APOLLO',
    'ADDRESS' => '10 DOWNING STREET'
  }
}, 'inheritance works with build_tree() overridden');


# Check that overriding escape_value() method works

my $ref = {
  'server' => {
    'address' => '12->14 "Puf&Stuf" Drive'
  }
};

$xsp = new XML::Simple::CDE();

$_ = $xsp->XMLout($ref);

like($_, qr{<opt>\s*
 <server\s+address="<!\[CDATA\[12->14\s+"Puf&Stuf"\s+Drive\]\]>"\s*/>\s*
</opt>}xs, 'inheritance works with escape_value() overridden');
