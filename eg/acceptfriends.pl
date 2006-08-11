#!/usr/bin/perl -w

# WWW::MySpaceBot Example
# Accept Friend Requests
use WWW::MySpaceBot;

my $myspace = new WWW::MySpaceBot;

my $username;
my $password;

if (@ARGV) {
   $username = shift;
   $password = shift;
}
else {
   print "Username> ";
   $username = <STDIN>;
   print "Password> ";
   $password = <STDIN>;

   chomp ($username,$password);
}

# Log in.
if ($myspace->login ($username,$password)) {
	print "Login Successful\n";
}
else {
	print "Login Failed\n";
}

print "My FriendID: " . $myspace->myFriendID or exit;
print "\n\n";

# Get friend requests.
if ($myspace->newFriendRequests) {
	my $requests = $myspace->friendRequests;

	foreach my $FriendID (keys %{$requests}) {
		print "Approving Friend: $FriendID $requests->{$FriendID}\n";
		$myspace->approveFriend ($FriendID);
	}

	print "\nApproved " . scalar(keys %{$requests}) . " pending friend requests.\n";
}
else {
	print "There were no new friend requests.\n";
}