#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';
use utf8;
use open ":std", ":encoding(UTF-8)";
my $URL = shift;
my ($USERNAME, $PASSWORD);

$| = 1;
($USERNAME, $PASSWORD) = (shift, shift);
print "Will test against [$URL] with non-admin [$USERNAME/$PASSWORD]\n";

use WWW::Mechanize ();
my $mech = new WWW::Mechanize(autocheck => 1, strict_forms => 1, cookie_jar => {});
$mech->default_header('Accept' => '*/*');
$mech->get($URL);

$mech->set_visible($USERNAME, $PASSWORD);
$mech->submit();

print $mech->status(), "\n";
# $mech->dump_headers();
$mech->content() =~ /You are authenticated as bob, but are not authorized to access this page/ or die;

($USERNAME, $PASSWORD) = (shift, shift);
print "Will log in with local admin [$USERNAME/$PASSWORD]\n";

$mech->set_visible($USERNAME, $PASSWORD);
$mech->submit();

print $mech->status(), "\n";
$mech->content() =~ /Models in the Authentication and Authorization application/ or die;

$mech->follow_link(text => "Users");

$mech->content() =~ /\b$USERNAME\b.*field-is_staff.*alt=.True/ or die;
$mech->content() =~ /\bbob\b.*robert\.chase\@example\.test.*Robert.*Chase.*field-is_staff.*alt=.False/ or die;
$mech->content() =~ /\bdavid\b/ and die "The accounts should have gotten created with the first logon";

$mech->follow_link(text => "bob");

$mech->content() =~ m#<option value="1">ext:admins</option># or die;
$mech->content() =~ m#<option value="2">ext:group-2</option># or die;
$mech->content() =~ m#<option value="3" selected>ext:group-3</option># or die;


my $dmech = new WWW::Mechanize(autocheck => 1, strict_forms => 1, cookie_jar => {});
$dmech->default_header('Accept' => '*/*');
$dmech->get($URL);

($USERNAME, $PASSWORD) = (shift, shift);
print "Will log in with ext:admin [$USERNAME/$PASSWORD]\n";

$dmech->set_visible($USERNAME, $PASSWORD);
$dmech->submit();

print "Users with the staff flag still do not have any default permissions\n";
print "  but at least they are let into the /admin/ application\n";
$dmech->content() =~ /You don.t have permission to view or edit anything/ or die;

print "Test logout\n";
if ($dmech->find_link(text => "Log out")) {
	$dmech->follow_link(text => "Log out");
} else {
	$dmech->form_id('logout-form');
	$dmech->submit();
}
$dmech->content() =~ /Logged out/ or die;

print "Follow the iframe to also log out from the IdP\n";
$dmech->follow_link(url_regex => qr/^\/openidc-redirect-uri\?logout=/);
$dmech->back();

print "And login again\n";
$dmech->follow_link(text => "Home");

$dmech->set_visible($USERNAME, $PASSWORD);
$dmech->submit();

$dmech->content() =~ /You don.t have permission to view or edit anything/ or die;


print "Will check the user as local admin\n";
$mech->back();
$mech->reload();

$mech->content() =~ /\b$USERNAME\b.*davidk\@example\.test.*David.*Křížala.*field-is_staff.*alt=.True/ or die;

$mech->follow_link(text => "david");

$mech->content() =~ m#<option value="1" selected>ext:admins</option># or die;
$mech->content() =~ m#<option value="2" selected>ext:group-2</option># or die;
$mech->content() =~ m#<option value="3">ext:group-3</option># or die;

if ($mech->find_link(text => "Log out")) {
	$mech->follow_link(text => "Log out");
} else {
	$mech->form_id('logout-form');
	$mech->submit();
}

$mech->content() =~ /Logged out/ or die;

sleep 1;
print "OK $0.\n";
