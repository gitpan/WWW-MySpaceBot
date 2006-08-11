package WWW::MySpaceBot;

use strict;
use warnings;
use LWP::UserAgent;
use LWP::ConnCache;
use HTTP::Cookies;
use Data::Dumper;

our $VERSION = '0.01';

# MySpace URLs
our $uris = {
	root            => 'http://www.myspace.com/',
	login           => 'http://login.myspace.com/index.cfm?fuseaction=login.process',
	home            => 'http://home.myspace.com/index.cfm?fuseAction=user',
	friendRequests  => 'http://mail.myspace.com/index.cfm?fuseaction=mail.friendRequests',
	processFriendRequests => 'http://mail.myspace.com/index.cfm?fuseaction=mail.processFriendRequests',
	bulletin        => 'http://bulletin.myspace.com/index.cfm?fuseaction=bulletin',
	bulletinPages   => 'http://bulletin.myspace.com/index.cfm?fuseaction=bulletin&page=',
	readBulletin    => 'http://bulletin.myspace.com/index.cfm?fuseaction=bulletin.read&messageID=',
	editBulletin    => 'http://bulletin.myspace.com/index.cfm?fuseaction=bulletin.edit',
	confirmBulletin => 'http://bulletin.myspace.com/index.cfm?fuseaction=bulletin.confirm',
	updateBulletin  => 'http://bulletin.myspace.com/index.cfm?fuseaction=bulletin.update',
	deleteBulletin  => 'http://bulletin.myspace.com/index.cfm?fuseaction=bulletin.delete',
	viewFriends     => 'http://home.myspace.com/index.cfm?fuseaction=user.viewfriends&friendID=',
	viewComments    => 'http://comments.myspace.com/index.cfm?fuseaction=user.homeComments&friendID=',
	confirmComment  => 'http://comments.myspace.com/index.cfm?fuseaction=user.ConfirmComment',
	addComment      => 'http://comments.myspace.com/index.cfm?fuseaction=user.addComment',
	viewProfile     => 'http://profile.myspace.com/index.cfm?fuseaction=user.viewprofile&friendID=',
	inbox           => 'http://mail.myspace.com/index.cfm?fuseaction=mail.inbox',
	inboxPages      => 'http://mail.myspace.com/index.cfm?fuseaction=mail.inbox&page=',
	readMessage     => 'http://mail.myspace.com/index.cfm?fuseaction=mail.readmessage&messageID=',
	writeMessage    => 'http://mail.myspace.com/index.cfm?fuseaction=mail.message&friendID=',
	sendMessage     => 'http://mail.myspace.com/index.cfm?fuseaction=mail.sendmessage',
	messageSent     => 'http://mail.myspace.com/index.cfm?fuseaction=mail.messagesent&friendID=',
	previewInterests => 'http://editprofile.myspace.com/index.cfm?fuseaction=profile.previewInterests',
	processInterests => 'http://editprofile.myspace.com/index.cfm?fuseaction=profile.processInterests',
};

# Regular Expressions
our $reg = {
	verifyHomepage  => 'My Mail',
	advertisement   => 'skip this advertisement',
	newMessages     => '<div id=\"indicatorMail\" class=\"show indicator\">',
	newFriends      => '<div id=\"indicatorFriendRequest\" class=\"show indicator\">',
	newComments     => '<div id=\"indicatorComments\" class=\"show indicator\">',
	newPictures     => '<div id=\"indicatorImageComments\" class=\"show indicator\">',
	newBlogComments => '<div id=\"indicatorBlogComments\" class=\"show indicator\">',
	newBlogs        => '<div id=\"indicatorBlogs\" class=\"show indicator\">',
	newEvents       => '<div id=\"indicatorEvents\" class=\"show indicator\">',
	newBirthdays    => '<div id=\"indicatorBirthday\" class=\"show indicator\">',
	newStudents     => 'NEW Students!',
	myProfile       => '<a id=\"ctl00_Main_ctl00_Welcome1_ViewMyProfileHyperLink\" href=\"http:\/\/profile\.myspace\.com\/'
		. 'index\.cfm\?fuseaction=user\.viewprofile\&amp\;friendid=(.*?)\">Profile<\/a>',
	myUsername      => 'Hello\,\&nbsp\;(.*?)\!',
	friendRequests  => '<a href=\"http:\/\/profile\.myspace\.com\/index\.cfm\?fuseaction=user\.viewprofile\&friendID=(.*?)\">'
		. '(.*?)<\/a><\/span> wants to be your friend\!',
	approveFriends  => '<td><input type=\"button\" name=\"approve\" value=\" Approve \" '
		. 'onClick=\"document\.singleRequestForm\.requestGUID\.value=\'(.*?)\'\; '
		. 'document\.singleRequestForm\.actionType\.value=\'0\'; document\.singleRequestForm\.submit\(\)\;\"><\/td>',
	bulletinWrapper => '<tr bgcolor=\"ffffff\" class=\"text11\">(.*?)<\/tr>',
	bulletinPoster  => '<\/a>.*?<a href=\"http:\/\/profile\.myspace\.com\/index\.cfm\?fuseaction=user\.viewprofile\&friendID='
		. '(\d+?)\">(.*?)<\/a>',
	bulletinSubject => '<a href=\"http:\/\/bulletin\.myspace\.com\/index\.cfm\?fuseaction=bulletin\.read\&messageID='
		. '(\d+?)\&.*?\">(.*?)<\/a>',
	readBulPoster   => '<span class=\"text\"><A HREF=\"http:\/\/profile\.myspace\.com\/index\.cfm\?fuseaction=user\.'
		. 'viewprofile\&friendID=(\d+)">(.*?)<\/a><\/span><br>',
	readBulSubject  => 'Subject:<\/span><\/td><newline><td width=\"86\%\"><font size=\"2\" face=\"verdana\">(.*?)'
		. '<\/font><\/td>',
	readBulMessage  => '<span class=\"blacktextnb10\"><font size=\"2\" face=\"verdana\">(.*?)<\/td><newline><\/tr>',
	bulletinPosted  => 'Bulletin Has Been Posted',
	bulletinDeleted => 'Bulletin Has Been Deleted',
	dateStamp       => '(\w\w\w \d+\, \d\d\d\d \d+:\d\d (AM|PM))',
	hash            => '<input type=\"hidden\" name=\"hash\" value=\"(.*?)\">',
	hashCode        => '<input type=\"hidden\" name=\"hashcode\" value=\"(.*?)\">',
	friendPages     => '\&gt\;\&gt\;<\/a>\&nbsp\;\&nbsp\;of\&nbsp\;\&nbsp\;\&nbsp\;<a href=\"javascript:NextPage'
		. '\(\'\d+?\'\)\">(\d+?)<\/a>\&nbsp\;\&nbsp\;',
	friendLink      => '<a href=\"http:\/\/profile\.myspace\.com\/index\.cfm\?fuseaction=user\.viewprofile\&friendid='
		. '(.*?)\" id=\".*?\">(.*?)<\/a><br \/>',
	commentStart    => '<a href=\"http:\/\/profile\.myspace\.com\/index\.cfm\?fuseaction=user\.viewprofile\&friendID='
		. '(\d+?)\".*?>(.*?)<\/a>',
	commentText     => '^<\/span>',
	profileUsername => '<span class=\"nametext\">(.*?)<\/span>',
	profileHeadline => '<td class=\"text\" width=\"193\" bgcolor=\"#ffffff\" height=\"75\" align=\"left\">\"(.*?)\"<br>',
	profileAddress  => '<td><div align=\"left\">\&nbsp\;\&nbsp\;http:\/\/www\.myspace\.com\/(.*?)\&nbsp\;\&nbsp\;'
		. '<\/div><\/td>',
	profileLocation => '\"$headline\"<br><newline><br><newline>(.*?)<newline><br><newline>(.*?)<newline><br><newline>'
		. '(.*?)<newline><br><newline>(.*?)<newline>',
	profileDetails  => '<td id=\"Profile$label:\" width=\"175\" bgcolor=\"#d5e8fb\" style=\"WORD\-WRAP: break\-word\">(.*?)<\/td>',
	messagePages    => 'of \&nbsp\;.*?<a href=\"javascript:NextPage\(\'\d+\'\)\">(\d+)<\/a>',
	spanDateStamp   => '<span class=\"text\">$reg->{dateStamp}<\/span>',
	messageFrom     => '<span class=\"text\"><a href=\"http:\/\/profile\.myspace\.com\/index\.cfm\?fuseaction=user'
		. '\.viewprofile\&friendID=(\d+)\">(.*?)<\/a><\/span>',
	messageSubject  => '<a class=\"mailtext\" href=\"http:\/\/mail\.myspace\.com\/index\.cfm\?fuseaction=mail'
		. '\.readmessage\&messageID=(\d+)\&.*?\">(.*?)<\/a><\/td>',
	readMsgFrom     => '<span class=\"text\"><a href=\"http:\/\/profile\.myspace\.com\/index\.cfm\?fuseaction=user'
		. '\.viewprofile\&friendID=(\d+?)\">(.*?)<\/a><\/span>',
	readMsgSubject  => '<td width=\"86\%\"><font size=\"2\" face=\"verdana\">(.*?)<\/font><\/td>',
	readMsgBody     => '<td width=\"86%\"><span class=\"blacktextnb10\"><font size=\"2\"  face=\"verdana\">'
		. '(.*?)<br><br><br>.*?<\/font><\/span>',
	sendMsgConfirm  => 'Your Message Has Been Sent',
	profileConfirm  => 'To disable clickable links on your interests',
	errors          => {
		unexpected => 'Sorry! an unexpected error has occurred\.',
		disabled   => '<b>This user\'s profile has been temporarily '
			. 'disabled for special maintenance.<br>',
		maintain   => 'This profile is undergoing routine maintenance. '
			. 'We apologize for the inconvenience!',
		mail       => 'We\'re doing some maintenance on the mail for certain users\.  '
			. 'You can take this opportunity to leave your friend a swell comment '
			. 'while we work on it\. :\)',
	},
};

######################################
## Core Methods                     ##
######################################

sub new {
	my $class = shift;

	my $self = {
		debug    => 0,
		dumper   => 0,
		browser  => undef, # UserAgent Object
		agent    => "WWW::MySpaceLWP/$VERSION",
		username => undef, # e-mail address
		password => undef, # password
		cookies  => './cookies.lwp',
		autoscan => 1,     # Auto-scanHomepage on successful login

		# Internals
		logged_in => 0,
		myid      => 0, # MY FriendID.
		mynick    => 0, # MY Profile Name
		handlers  => {
			Error => sub {
				my ($self,$error) = @_;

				print "ERROR: $error\n";

				if ($error =~ /an unexpected error has occurred/i) {
					# Retry the last request.
					return $self->retry();
				}

				return undef;
			},
		}, # Event Handlers
		new_mail  => {
			messages  => 0, # New Messages!
			friends   => 0, # New Friend Requests!
			comments  => 0, # New Comments!
			pictures  => 0, # New Picture Comments!
			blog      => 0, # New Blog Comments!
			subscribe => 0, # New Blog Subscription Posts!
			events    => 0, # New Event Invitations!
			birthdays => 0, # New Birthdays!
			students  => 0, # New Students!
		},
		guids     => {
			# Save GUIDs of Friend Requests. Keys are the FriendIDs.
		},
		discovery   => {}, # We'll log info on each FriendID we discover on our way
		friendPages => {}, # Save how many pages of friends users have
		mailPages   => 0,  # Pages of messages in our inbox
		lastRequest => {}, # Details on the last request made
		@_,
	};

	bless ($self,$class);

	$self->makeAgent;

	return $self;
}

sub setHandler {
	my ($self,%args) = @_;

	foreach my $key (keys %args) {
		$self->{handlers}->{$key} = $args{$key};
	}

	return 1;
}
sub setHandlers {
	return shift->setHandler(@_);
}

sub makeAgent {
	my $self = shift;

	$self->{browser} = LWP::UserAgent->new;
	$self->{browser}->agent ($self->{agent});
	$self->{browser}->cookie_jar ( HTTP::Cookies->new (
		file => $self->{cookies},
	));
	$self->{browser}->conn_cache (LWP::ConnCache->new());
}

sub debug {
	my ($self,$string) = @_;

	print "$string\n" unless $self->{debug} == 0;
	return 1;
}

sub dump {
	my ($self,$filename,$data) = @_;

	return unless $self->{dumper};

	open (FILE, ">$filename");
	print FILE $data;
	close (FILE);
}

sub request {
	my ($self,$method,$url,$data) = @_;

	$self->debug ("Accessing $method $url...");

	$self->{lastRequest} = {
		Method => $method,
		URL    => $url,
		Data   => $data,
	};

	if ($method eq 'GET') {
		my $reply = $self->{browser}->get ($url);
		if ($reply->is_success) {
			my ($error,$code) = $self->errorCheck ($reply->content);
			if ($error) {
				# Do we have a handler?
				if (defined $self->{handlers}->{Error}) {
					return &{$self->{handlers}->{Error}} ($self,$code);
				}
				else {
					warn "ERROR: $code";
				}

				return undef;
			}

			return $reply->content;
		}
		else {
			# We may be getting a redirect.
			if (defined $reply->headers->{location} && length $reply->headers->{location}) {
				$self->debug ("Got a redirection from $url\n"
					. "to " . $reply->headers->{location});
				return $self->request ('GET',$reply->headers->{location});
			}

			warn "Could not access $url: " . $reply->status_line . "\n"
				. Dumper($reply->headers);
			$self->makeAgent if $reply->status_line =~ /^500 Server closed connection/i;
			return undef;
		}
	}
	elsif ($method eq 'POST') {
		my $reply = $self->{browser}->post ($url, $data);
		if ($reply->is_success) {
			my ($error,$code) = $self->errorCheck ($reply->content);
			if ($error) {
				# Do we have a handler?
				if (defined $self->{handlers}->{Error}) {
					return &{$self->{handlers}->{Error}} ($self,$code);
				}
				else {
					warn "ERROR: $code";
				}

				return undef;
			}

			return $reply->content;
		}
		else {
			# We may be getting a redirect.
			if (defined $reply->headers->{location} && length $reply->headers->{location}) {
				$self->debug ("Got a redirection from $url\n"
					. "to " . $reply->headers->{location});
				return $self->request ('GET',$reply->headers->{location});
			}

			warn "Could not access $url: " . $reply->status_line . "\n"
				. Dumper($reply->headers);
			$self->makeAgent if $reply->status_line =~ /^500 Server closed connection/i;
			return undef;
		}
	}
	else {
		warn "Unsupported HTTP method $method";
		return undef;
	}
}

sub retry {
	my ($self) = @_;

	if (defined $self->{lastRequest}) {
		my $method = $self->{lastRequest}->{Method};
		my $url    = $self->{lastRequest}->{URL};
		my $data   = $self->{lastRequest}->{Data};

		return $self->request ($method,$url,$data);
	}
	else {
		warn "No requests have been made yet!";
		return 0;
	}
}

######################################
## Authentication and Homepage      ##
######################################

sub login {
	my $self = shift;

	if (scalar(@_) == 2) {
		$self->{username} = shift;
		$self->{password} = shift;
	}
	elsif (scalar(@_) == 4) {
		my (%data) = (@_);
		$self->{username} = $data{username} || $data{email};
		$self->{password} = $data{password};
	}
	else {
		if (not defined $self->{username} || not defined $self->{password}) {
			warn "login() must be called with a username and password";
			return 0;
		}
	}

	$self->debug ("Username=$self->{username}; Password=$self->{password}");

	# Send the request.
	my $reply = $self->request ('POST',$uris->{login}, {
		email    => $self->{username},
		password => $self->{password},
	});

	$self->dump ("login.html",$reply);

	# Verify the login.
	if ($reply =~ /$reg->{verifyHomepage}/) {
		$self->{logged_in} = 1;

		# Scan for new things.
		$self->scanHomepage (undef,$reply) if $self->{autoscan};

		return 1;
	}
	elsif ($reply =~ /$reg->{advertisement}/i) {
		$self->{logged_in} = 1;

		# We got an advertisement.
		$self->scanHomepage ($uris->{home}) if $self->{autoscan};

		return 1;
	}
	else {
		return 0;
	}
}

sub isLoggedIn {
	my $self = shift;

	# This sub should return TRUE if there's an error...
	#   return undef unless $self->isLoggedIn

	if ($self->{logged_in} == 1) {
		return 1;
	}
	else {
		warn "You aren't logged in to MySpace!";
		return 0;
	}
}

sub myAccountName {
	my $self = shift;

	if ($self->{logged_in}) {
		return $self->{username};
	}
	else {
		warn "Can't get your AccountName -- Not logged in!";
		return undef;
	}
}

sub myPassword {
	my $self = shift;

	if ($self->{logged_in}) {
		return $self->{password};
	}
	else {
		warn "Can't get your Password -- Not logged in!";
		return undef;
	}
}

sub myFriendID {
	my $self = shift;

	if ($self->{logged_in}) {
		return $self->{myid};
	}
	else {
		warn "Can't get your FriendID -- Not logged in!";
		return undef;
	}
}

sub myNickname {
	my $self = shift;

	if ($self->{logged_in}) {
		return $self->{mynick};
	}
	else {
		warn "Can't get your Nickname -- Not logged in!";
		return undef;
	}
}

sub myUsername {
	return shift->myNickname;
}

sub scanHomepage {
	my ($self,$url,$content) = @_;

	# If $content is defined, $url isn't needed.
	if (not defined $content) {
		$content = $self->request ('GET',$url);
	}

	# Format the content for easy searching.
	$content =~ s/\n//g;

	# Regular Expressions.
	my %regexp = (
		messages  => $reg->{newMessages},
		friends   => $reg->{newFriends},
		comments  => $reg->{newComments},
		pictures  => $reg->{newPictures},
		blog      => $reg->{newBlogComments},
		subscribe => $reg->{newBlogs},
		events    => $reg->{newEvents},
		birthdays => $reg->{newBirthdays},
		students  => $reg->{newStudents},
	);

	foreach my $str (keys %regexp) {
		if ($content =~ /$regexp{$str}/i) {
			$self->{new_mail}->{$str} = 1;
		}
	}

	my $profile = $reg->{myProfile};
	my $username = $reg->{myUsername};
	my ($FriendID) = $content =~ /$profile/i;
	my ($Nickname) = $content =~ /$username/i;

	$self->{myid} = $FriendID;
	$self->{mynick} = $Nickname;
}

######################################
## Friend Requests                  ##
######################################

sub friendRequests {
	my ($self) = @_;

	return undef unless $self->isLoggedIn;

	my $requests = {};

	# Get the friend requests page.
	my $reply = $self->request ('GET',$uris->{friendRequests});
	$self->dump ("friends.html",$reply);

	# Gather all the requests.
	my $regexp  = $reg->{friendRequests};
	my $approve = $reg->{approveFriends};
	while ($reply =~ /$regexp/i) {
		my $FriendID = $1;
		my $Username = $2;
		$self->debug ("Friend Request: $FriendID $Username");

		$requests->{$FriendID} = $Username;

		my ($guid) = $reply =~ /$approve/i;
		$reply =~ s/$approve//i;
		$self->debug ("$Username GUID: $guid");

		$self->{guids}->{$FriendID} = $guid;

		$reply =~ s/$regexp//i;

		# Save these discoveries.
		$self->{discovery}->{$FriendID}->{Username} = $Username;
	}

	return $requests;
}

sub approveFriend {
	my ($self,$FriendID) = @_;

	return undef unless $self->isLoggedIn;

	# Do we have a GUID from him?
	if (not exists $self->{guids}->{$FriendID}) {
		warn "We don't have the GUID for FriendID $FriendID. Call friendRequests() first!";
		return 0;
	}

	# Submit the deny request.
	my $reply = $self->request ('POST',$uris->{processFriendRequests}, {
		requestType => 'SINGLE',
		requestGUID => $self->{guids}->{$FriendID},
		actionType  => '0',
	});

	$self->dump ("approved.html",$reply);

	return 1;
}

sub denyFriend {
	my ($self,$FriendID) = @_;

	return undef unless $self->isLoggedIn;

	# Do we have a GUID from him?
	if (not exists $self->{guids}->{$FriendID}) {
		warn "We don't have the GUID for FriendID $FriendID. Call friendRequests() first!";
		return 0;
	}

	# Submit the deny request.
	my $reply = $self->request ('POST',$uris->{processFriendRequests}, {
		requestType => 'SINGLE',
		requestGUID => $self->{guids}->{$FriendID},
		actionType  => '1',
	});

	$self->dump ("denied.html",$reply);

	return 1;
}

######################################
## Bulletins                        ##
######################################

sub getBulletins {
	my $self = shift;
	my $page = shift || 1;

	return undef unless $self->isLoggedIn;

	# Get the content.
	my $get = $uris->{bulletin};
	$get = $uris->{bulletinPages} . ($page - 1) if $page > 1;
	my $reply = $self->request ('GET', $get);

	# Output for the bulletins.
	my $output = [];

	# Format the reply and begin searching.
	$reply =~ s/\n//g;

	while ($reply =~ /$reg->{bulletinWrapper}/i) {
		my $bulletin = $1;

		my $FriendID = 0;
		my $name = '';
		my $time = '';
		my $BulletinID = 0;
		my $subject = '';

		if ($bulletin =~ /$reg->{bulletinPoster}/i) {
			$FriendID = $1;
			$name     = $2;
		}
		if ($bulletin =~ /$reg->{dateStamp}/) {
			$time = $1;
		}
		if ($bulletin =~ /$reg->{bulletinSubject}/i) {
			$BulletinID = $1;
			$subject    = $2;
		}

		# Save these discoveries.
		$self->{discovery}->{$FriendID}->{Username} = $name;

		push (@{$output}, {
			FriendID   => $FriendID,
			Username   => $name,
			Date       => $time,
			BulletinID => $BulletinID,
			Subject    => $subject,
		});

		$reply =~ s/$reg->{bulletinWrapper}//i;
	}

	return $output;
}

sub readBulletin {
	my ($self,$BulletinID) = @_;

	return undef unless $self->isLoggedIn;

	# Get the bulletin.
	my $reply = $self->request ('GET', $uris->{readBulletin} . $BulletinID);

	my $FriendID = '';
	my $username = '';
	my $date     = '';
	my $subject  = '';
	my $message  = '';

	# Format the reply.
	$reply =~ s/\n/<newline>/ig;
	$reply =~ s/\r//ig;
	$reply =~ s/\t//ig;

	$self->dump ("bulletin.html",$reply);

	if ($reply =~ /$reg->{readBulPoster}/i) {
		$FriendID = $1;
		$username = $2;
	}
	if ($reply =~ /$reg->{dateStamp}/i) {
		$date = $1;
	}
	if ($reply =~ /$reg->{readBulSubject}/i) {
		$subject = $1;
	}
	if ($reply =~ /$reg->{readBulMessage}/i) {
		$message = $1;
	}

	$message =~ s/<newline>/\n/ig;

	# Save this discovery.
	$self->{discovery}->{$FriendID}->{Username} = $username;

	return {
		FriendID => $FriendID,
		Username => $username,
		Date     => $date,
		Subject  => $subject,
		Message  => $message,
	};
}

sub postBulletin {
	my ($self,%args) = @_;

	return undef unless $self->isLoggedIn;

	# Incoming args should be case-insensitive.
	my %fields = ();
	foreach my $key (keys %args) {
		my $lc = lc($key); $lc =~ s/ //g;
		$fields{$lc} = $args{$key};
	}

	# We'll need to get a Post Bulletin page first to get a hash.
	my $form = $self->request ('GET', $uris->{editBulletin});
	$form =~ s/\n//g; $form =~ s/\r//g;
	my ($hash) = $form =~ /$reg->{hash}/i;

	# Now we can post the bulletin.
	my $reply = $self->request ('POST', $uris->{confirmBulletin}, {
		subject => $fields{subject},
		body    => $fields{message} || $fields{body},
		hash    => $hash,
		submit  => '-Post-',
	});
	$reply =~ s/\n//g; $reply =~ s/\r//g;

	# Now we'll have to confirm the bulletin.
	my ($hashcode) = $reply =~ /$reg->{hashCode}/i;
	my ($confirm)  = $reply =~ /$reg->{hash}/i;

	# Finally... confirm.
	my $finish = $self->request ('POST', $uris->{updateBulletin}, {
		groupID => '0',
		hashcode => $hashcode,
		hash     => $confirm,
		subject  => $fields{subject},
		body     => $fields{message} || $fields{body},
	});

	# And see if it was successful.
	if ($finish =~ /$reg->{bulletinPosted}/) {
		return 1;
	}
	else {
		return 0;
	}
}

sub deleteBulletin {
	my ($self,$BulletinID) = @_;

	return undef unless $self->isLoggedIn;

	# Get the Delete Confirm page.
	my $reply = $self->request ('POST', $uris->{deleteBulletin}, {
		messageID => $BulletinID,
	});

	if ($reply =~ /$reg->{bulletinDeleted}/i) {
		return 1;
	}
	else {
		return 0;
	}
}

######################################
## Friends Lists                    ##
######################################

sub getFriends {
	my $self = shift;
	my $friend = shift;
	my $page = shift || 1;

	my $get = $uris->{viewFriends} . $friend;
	$get = $uris->{viewFriends} . $friend . "&page=$page" if $page > 1;
	my $reply = $self->request ('GET',$get);

	if ($reply =~ /$reg->{friendPages}/i) {
		my $pageCount = $1;
		$self->{friendPages}->{$friend} = $pageCount;
	}

	my $output = [];
	while ($reply =~ /$reg->{friendLink}/i) {
		my $FriendID = $1;
		my $Username = $2;

		# print "Found Friend $FriendID\n";

		$reply =~ s/$reg->{friendLink}//i;
		next if $Username =~ /^<img/i;

		push (@{$output}, {
			FriendID => $FriendID,
			Username => $Username,
		});

		# Save the discovery.
		$self->{discovery}->{$FriendID}->{Username} = $Username unless $Username =~ /[^\.]\.\.$/;
	}

	return $output;
}

sub getFriendsPages {
	my $self = shift;
	my $friend = shift;

	if (defined $self->{friendPages}->{$friend}) {
		return $self->{friendPages}->{$friend};
	}
	else {
		$self->getFriends ($friend);
		return $self->{friendPages}->{$friend};
	}
}

######################################
## Comment Stuff                    ##
######################################

sub getComments {
	my ($self,$friend,$page) = @_;
	$friend = $self->{myid} unless defined $friend;
	$page = 1 unless defined $page;

	my $get = $uris->{viewComments} . $friend;
	$get = $uris->{viewComments} . $friend . "&page=" . ($page - 1) if $page > 1;
	my $reply = $self->request ('GET', $get);
	$reply =~ s/\r//g;

	my $output = [];

	# We'll do this one line-for-line.
	my $inComment = 0;
	my $inText = 0;
	my $onID = 0;
	my $onNick = '';
	my $onDate = '';
	my @onMsg = ();
	my $i = -1;
	my @lines = split(/\n/, $reply);
	foreach my $line (@lines) {
		$i++;
		print ($i + 1);
		print "\n";
		if ($inComment == 0) {
			if ($line =~ /$reg->{commentStart}/i) {
				$inComment = 1;
				$onID = $1;
				$onNick = $2;
				$self->{discovery}->{$onID}->{Username} = $onNick;
				print "Found new comment ($onID - $onNick)\n";
				<STDIN>;
				next;
			}
		}
		else {
			if ($line =~ /$reg->{dateStamp}/i) {
				$onDate = $1;
				print "\tFound Dateline: $onDate\n";
				<STDIN>;
				next;
			}
			if ($line =~ /$reg->{commentText}/i) {
				$inText = 1;
				print "\tComment Starting!\n";
				<STDIN>;
				next;
			}

			if ($inText == 1) {
				my $j = $i + 1;
				if ($lines[$j] =~ /^\t\t\t\t$/ || $lines[$j] =~ /^\t\t\t\t\t/) {
					push (@onMsg, $line);

					print "\t\tFound Line $line\n";

					print "\t*** Found Delimeter!!!\n"
						. "\t\tFriendID = $onID\n"
						. "\t\tUsername = $onNick\n"
						. "\t\tDate     = $onDate\n"
						. "\t\tMessage  = " . scalar(@onMsg) . "\n";

					for (my $i = 0; defined $onMsg[$i]; $i++) {
						$onMsg[$i] =~ s/^\t+//i;
					}

					push (@{$output}, {
						FriendID => $onID,
						Username => $onNick,
						Date     => $onDate,
						Message  => join("\n",@onMsg),
					});

					$inText = 0;
					$inComment = 0;
					$onID = 0;
					$onNick = '';
					$onDate = '';
					@onMsg = ();

					print "\tGoing on to next comment\n";
					<STDIN>;

					next;
				}

				push (@onMsg, $line);
				print "\t\tFound Line $line\n";
				<STDIN>;
			}
		}
	}

	return $output;
}

sub postComment {
	my ($self,%args) = @_;

	return undef unless $self->isLoggedIn;

	# Incoming args should be case-insensitive.
	my %fields = ();
	foreach my $key (keys %args) {
		my $lc = lc($key); $lc =~ s/ //g;
		$fields{$lc} = $args{$key};
	}

	# We'll have to confirm the comment.
	my $confirm = $self->request ('POST', $uris->{confirmComments}, {
		friendID   => $fields{friendid},
		f_comments => $fields{body} || $fields{message},
	});

	my ($hashcode) = $confirm =~ /$reg->{hashCode}/i;

	my $finish = $self->request ('POST', $uris->{addComment}, {
		hashcode   => $hashcode,
		FriendID   => $fields{friendid},
		f_comments => $fields{body} || $fields{message},
	});

	return 1;
}

sub commentFriends {
	my ($self,$msg) = @_;

	# Get a list of FriendIDs.
	my @ids = ();

	my $done = 0;
	my $pages = 0;
	my $page = 1;
	until ($done) {
		$page++ if ($pages > 0 && $page < $pages);

		print "Grabbing Page $page (page=$page; pages=$pages;done=$done)\n";
		<STDIN>;
		my $friends = $self->getFriends ($self->myFriendID,$page);
		if (not defined $friends) {
			$page-- if $page > 1;
			next;
		}
		foreach (@{$friends}) {
			next if $_->{FriendID} == 6221; # Skip Tom
			push (@ids, $_->{FriendID});
		}

		print "Found " . scalar(@{$friends}) . " from this page\n";
		<STDIN>;

		if ($pages == 0) {
			$pages = $self->getFriendsPages ($self->myFriendID);
		}

		$done = 1 if $page >= $pages;
	}

	$self->dump ("IDs.txt", join("\n",@ids));
}

######################################
## Profile Scanning                 ##
######################################

sub scanProfile {
	my ($self,$friend) = @_;

	# Get this friend's profile page.
	my $reply = $self->request ('GET', $uris->{viewProfile} . $friend);
	$reply =~ s/\n/<newline>/g;
	$reply =~ s/\r//g;
	$reply =~ s/\t//g;
	$reply =~ s/\s\s\s\s//g;

	# Harvest information.
	my ($username) = $reply =~ /$reg->{profileUsername}/i;
	my ($headline) = $reply =~ /$reg->{profileHeadline}/i;
	my ($address)  = $reply =~ /$reg->{profileAddress}/i;

	my ($sex,$age,$state,$country) = ('','','','');
	if ($reply =~ /$reg->{profileLocation}/i) {
		$sex     = $1;
		$age     = $2;
		$state   = $3;
		$country = $4;
		$age =~ s/\syears old$//i;
	}

	my %details = (
		Status          => 'undefined',
		'Here for'      => 'undefined',
		Orientation     => 'undefined',
		Hometown        => 'undefined',
		'Body type'     => 'undefined',
		Ethnicity       => 'undefined',
		Religion        => 'undefined',
		'Zodiac Sign'   => 'undefined',
		'Smoke / Drink' => 'undefined',
		Children        => 'undefined',
		Education       => 'undefined',
	);
	foreach my $label (keys %details) {
		if ($reply =~ /$reg->{profileDetails}/i) {
			$details{$label} = $1;
		}
	}

	$username =~ s/<newline>/\n/g;
	$headline =~ s/<newline>/\n/g;
	$address  =~ s/<newline>/\n/g;

	# Save information.
	$self->{discovery}->{$friend} = {
		Username => $username,
		Headline => $headline,
		Profile  => $uris->{root} . $address,
		Gender   => $sex,
		Age      => $age,
		State    => $state,
		Country  => $country,
		Details  => {
			%details,
		},
	};

	return 1;
}

sub friendInfo {
	my ($self,$type,$friend,$force) = @_;

	if (not exists $self->{discovery}->{$friend} || (defined $force && $force == 1)) {
		$self->scanProfile ($friend);
	}

	return $self->{discovery}->{$friend}->{$type};
}

sub friendUsername {
	return shift->friendInfo ('Username',@_);
}

sub friendHeadline {
	return shift->friendInfo ('Headline',@_);
}

sub friendAddress {
	return shift->friendInfo ('Profile',@_);
}

sub friendGender {
	return shift->friendInfo ('Gender',@_);
}

sub friendAge {
	return shift->friendInfo ('Age',@_);
}

sub friendLocation {
	return shift->friendInfo ('State',@_);
}

sub friendCountry {
	return shift->friendInfo ('Country',@_);
}

sub friendDetails {
	my ($self,$friend) = @_;
	return $self->{discovery}->{$friend}->{Details};
}

######################################
## Private Messaging                ##
######################################

sub getMessages {
	my ($self,$page) = @_;

	return undef unless $self->isLoggedIn;

	# If $page isn't defined, we'll just get the first page.
	my $url = $uris->{inbox};
	$url = $uris->{inbox} . $page if defined $page;

	# Get the first page to start with.
	my $reply = $self->request ('GET',$url);

	# Format the page.
	$reply =~ s/\n//g;
	$reply =~ s/\t+//g;

	# See how many pages there are.
	if ($reply =~ /$reg->{messagePages}/i) {
		my $count = $1;
		$self->debug ("Found $count pages of messages!");
		$self->{mailPages} = $count;
	}

	# See how many new messages we have.
	my $newMessages = 0;
	my $oldMessages = 0;
	my $info = [];

	$self->debug ("Scanning for messages...");

	while ($reply =~ /$reg->{spanDateStamp}/i) {
		my $date = $1;

		my $FriendID  = 0;
		my $Username  = '';
		my $MessageID = 0;
		my $Subject   = '';

		if ($reply =~ /$reg->{messageFrom}/i) {
			$FriendID = $1;
			$Username = $2;
			$reply =~ s/$reg->{messageFrom}//i;
		}

		if ($reply =~ /$reg->{messageSubject}/i) {
			$MessageID = $1;
			$Subject   = $2;
			$reply =~ s/$reg->{messageSubject}//i;
		}

		push (@{$info}, {
			FriendID  => $FriendID,
			Username  => $Username,
			MessageID => $MessageID,
			Subject   => $Subject,
			Date      => $date,
		});

		$reply =~ s/$reg->{spanDateStamp}//i;
	}

	return $info;
}

sub getMessagePages {
	my ($self) = @_;

	return undef unless $self->isLoggedIn;

	return $self->{mailPages};
}

sub readMessage {
	my ($self,$MessageID) = @_;

	return undef unless $self->isLoggedIn;

	# Get this message.
	my $reply = $self->request ('GET',$uris->{readMessage} . $MessageID);

	my $FriendID = 0;
	my $Username = '';
	my $Date     = '';
	my $Subject  = '';
	my $Message  = '';

	if ($reply =~ /$reg->{readMsgFrom}/i) {
		$FriendID = $1;
		$Username = $2;
	}

	if ($reply =~ /$reg->{dateStamp}/i) {
		$Date = $1;
	}

	if ($reply =~ /$reg->{readMsgSubject}/i) {
		$Subject = $1;
	}

	# Now format the page to easily get the message.
	$reply =~ s/\n\r/\n/g;
	$reply =~ s/\n/<newline>/g;
	$reply =~ s/\r//g;

	if ($reply =~ /$reg->{readMsgBody}/i) {
		$Message = $1;
	}

	# Get the message back to normal again.
	$Message =~ s/<newline>/\n/g;
	$Message =~ s/^\t+// while $Message =~ /^\t/;

	return {
		FriendID => $FriendID,
		Username => $Username,
		Date     => $Date,
		Subject  => $Subject,
		Message  => $Message,
	};
}

sub sendMessage {
	my ($self,%args) = @_;

	return undef unless $self->isLoggedIn;

	# Incoming args should be case-insensitive.
	my %fields = ();
	foreach my $key (keys %args) {
		my $lc = lc($key); $lc =~ s/ //g;
		$fields{$lc} = $args{$key};
	}

	# Get a hash code.
	my $request = $self->request ('GET', $uris->{writeMessage} . $fields{friendid});
	my ($hash) = $request =~ /$reg->{hashCode}/i;

	# Post.
	my $reply = $self->request ('POST', $uris->{sendMessage}, {
		hashcode => $hash,
		messageType => '0',
		toUserID    => $fields{friendid},
		errorReturnUrl => $uris->{writeMessage} . $fields{friendid},
		returnUrl      => $uris->{messageSent} . $fields{friendid},
		subject        => $fields{subject},
		mailbody       => $fields{body} || $fields{message},
		doSend         => '-Send-',
	});

	if ($reply =~ /$reg->{sendMsgConfirm}/i) {
		return 1;
	}
	else {
		return 0;
	}
}

######################################
## Profile Editing Methods          ##
######################################

sub changeInterest {
	my ($self,$type,$text) = @_;

	# Interest Labels:
	# (headline|aboutme|LikeToMeet|general|music|movies|television|heroes|books)

	return undef unless $self->isLoggedIn;

	# Best to normalize the type.
	$type = lc($type); $type =~ s/ //g;

	return undef unless $type =~ /^(headline|aboutme|liketomeet|general|music|movies|television|heroes|books)$/i;

	my $label = $type;
	$label = 'LikeToMeet' if $label eq 'liketomeet';

	# Submit it to the preview page first.
	my $preview = $self->request ('POST', $uris->{previewInterests}, {
		interestLabel => $label,
		interest      => $text,
	});

	# Get our hash code.
	my ($hash) = $preview =~ /$reg->{hash}/i;

	# Submit it to the profile.
	my $reply = $self->request ('POST', $uris->{processInterests}, {
		hash => $hash,
		interest => $text,
		interestLabel => $label,
	});

	if ($reply =~ /$reg->{profileConfirm}/i) {
		return 1;
	}
	else {
		return 0;
	}
}

# Interest Shortcuts
sub changeHeadline {
	return shift->changeInterest ('headline',@_);
}
sub changeAboutMe {
	return shift->changeInterest ('aboutme',@_);
}
sub changeLikeToMeet {
	return shift->changeInterest ('liketomeet',@_);
}
sub changeGeneral {
	return shift->changeInterest ('general',@_);
}
sub changeMusic {
	return shift->changeInterest ('music',@_);
}
sub changeMovies {
	return shift->changeInterest ('movies',@_);
}
sub changeTelevision {
	return shift->changeInterest ('television',@_);
}
sub changeHeroes {
	return shift->changeInterest ('heroes',@_);
}
sub changeBooks {
	return shift->changeInterest ('books',@_);
}

######################################
## Checking New Mail Types          ##
######################################

sub newMessages {
	return shift->{new_mail}->{messages};
}
sub newFriendRequests {
	return shift->{new_mail}->{friends};
}
sub newComments {
	return shift->{new_mail}->{comments};
}
sub newPictureComments {
	return shift->{new_mail}->{pictures};
}
sub newBlogComments {
	return shift->{new_mail}->{blog};
}
sub newBlogs {
	return shift->{new_mail}->{subscribe};
}
sub newEvents {
	return shift->{new_mail}->{events};
}
sub newBirthdays {
	return shift->{new_mail}->{birthdays};
}
sub newStudents {
	return shift->{new_mail}->{students};
}

######################################
## Error Checking                   ##
######################################

sub errorCheck {
	my ($self,$content) = @_;

	my @errors = values %{$reg->{errors}};

	foreach my $regexp (@errors) {
		if ($content =~ /$regexp/sm) {
			return (1,$regexp);
		}
	}

	return (0,undef);
}

__END__;

=pod

=head1 NAME

WWW::MySpaceBot - A libwww-perl interface to MySpace.

=head1 SYNOPSIS

  use WWW::MySpaceBot;

  my $myspace = new WWW::MySpaceBot;

  # Sign In
  $myspace->login (
    email    => 'myname@yourdomain.com',
    password => 'big_secret_password',
  ) or die "Login Failed!";

  # Print some details
  print "My Friend ID: " . $myspace->myFriendID . "\n";
  print "My Username:  " . $myspace->myUsername . "\n";

  # Check for new friend requests.
  if ($myspace->newFriendRequests) {
    my $requests = $myspace->friendRequests;

    # Approve each of them.
    foreach my $FriendID (keys %{$requests}) {
      print "Approving Friend: $requests->{$FriendID}\n";
      $myspace->approveFriend ($FriendID);
    }
  }

=head1 DESCRIPTION

WWW::MySpaceBot is a Perl MySpace interface that uses libwww-perl, and is therefore
more portable without requiring any non-standard Perl modules.

=head1 CORE METHODS

=head2 new (%ARGS)

Create a new WWW::MySpaceBot object. You can pass in default variables here:

  debug    => Debug Mode
  dumper   => To dump HTML pages into files (for debugging)
  agent    => A User-Agent string to use
  username => Your MySpace username
  password => Your MySpace password
  cookies  => Path to a cookie jar
  autoscan => (0|1) Automatically scan the Homepage for new messages on login

=head2 makeAgent

Creates a new LWP::UserAgent.

=head2 debug ($MESSAGE)

Prints a debug string.

=head2 dump ($FILENAME, $CONTENT)

Dumps HTML content to a file (for debugging).

=head2 request (METHOD, URL[, FIELDS])

Sends an HTTP request to URL using method METHOD. If METHOD is 'POST', then
FIELDS should be the form fields to send in.

=head1 AUTHENTICATION AND HOMEPAGE METHODS

=head2 login ($USERNAME, $PASSWORD), login (%DETAILS)

Log in to MySpace. You can pass in $USERNAME and $PASSWORD in array form, or as a
hash. For the hash, the keys B<username> (or B<email>) and B<password> are used.

Returns true on successful connect.

=head2 isLoggedIn

Returns true if you are logged in.

=head2 myAccountName

Returns your account name (e-mail address you signed in with).

=head2 myPassword

Returns the password you provided at login.

=head2 myFriendID

Returns your Friend ID.

=head2 myNickname, myUsername

Returns your username.

=head2 scanHomepage ($URL[, $CONTENT])

Scans the homepage to find your username, FriendID, and to check for new messages,
comments, picture comments, friend requests, and other notifications.

=head1 NOTIFICATION METHODS

=head2 newMessages

Returns 1 or 0 indicating if you have a "New Messages!" notification.

=head2 newFriendRequests

Indicates if you have "New Friend Requests!"

=head2 newComments

Indicates if you have "New Comments!"

=head2 newPictureComments

Indicates if you have "New Picture Comments!"

=head2 newBlogComments

Indicates if you have "New Blog Comments!"

=head2 newBlogs

Indicates if you have "New Blog Subscription Posts!"

=head2 newEvents

Indicates if you have "New Event Invitations"

=head2 newBirthdays

Indicates if you have "New Birthdays!"

=head2 newStudents

Indicates if your school has "NEW Students!"

=head1 FRIEND REQUEST METHODS

=head2 friendRequests

Checks for new friend requests. Returns a hashref of Friend IDs (keys) and Usernames (values).
Also internally stores GUIDs for each Friend Request.

=head2 approveFriend ($FriendID)

Approves a pending friend request. You must call C<friendRequests> first so that you can get
their GUID. Returns true on success.

=head2 denyFriend ($FriendID)

Deny a friend request. Returns true on success.

=head1 FRIENDS LIST METHODS

=head2 getFriends ($FriendID[, $PAGE])

Gets the list of friends for $FriendID. $PAGE is optionally a specific page to get (defaults to 1).

Returns Friends in an arrayref of hashrefs, in the order they appeared on the page. The keys of each
hashref are:

  FriendID => Their FriendID
  Username => Their Username

=head2 getFriendsPages ($FriendID)

Gets the number of pages on C<$FriendID>'s Friends Pages. If you call this after at least one
C<getFriends()> call, it will be able to return the number instantly. Else it will need to call
C<getFriends()> for itself to find out.

=head1 COMMENT METHODS

=head2 getComments ($FriendID[, $PAGE])

Returns the comments that $FriendID has. Returns an arrayref of hashrefs. The hashref keys are
as follows:

  FriendID => Their FriendID
  Username => Their Username
  Date     => Timestamp of the comment
  Message  => The comment's body

=head2 postComment (%ARGS)

Post a comment on somebody's MySpace. C<%ARGS> is a hash:

  FriendID => The target's FriendID
  Message  => A comment to put on their MySpace
  Body     => An alternative to Message

=head2 commentFriends ($MESSAGE)

Posts C<$MESSAGE> as a comment to all of your friends.

=head1 PROFILE METHODS

=head2 scanProfile ($FriendID)

Scans C<$FriendID>'s profile page to find information retrievable in the following methods.

=head2 friendInfo ($TYPE, $FriendID[, $FORCE])

Retrieves a bit of information C<$TYPE> about C<$FriendID>. C<$TYPE> would be any of the
following:

  Username   Headline   Profile
  Gender     Age        State
  Country

This method will call C<scanProfile> if need-be. If C<$FORCE> is true, it will force
a re-grab of their profile page.

=head2 friendUsername ($FriendID[, $FORCE])

=head2 friendHeadline ($FriendID[, $FORCE])

=head2 friendAddress ($FriendID[, $FORCE])

=head2 friendGender ($FriendID[, $FORCE])

=head2 friendAge ($FriendID[, $FORCE])

=head2 friendLocation ($FriendID[, $FORCE])

=head2 friendCountry ($FriendID[, $FORCE])

Retrieves one piece of information about C<$FriendID>, to get their username, headline,
profile address, gender, age, state, and country respectively.

=head2 friendDetails ($FriendID)

Returns the details about $FriendID, as found in the "Details:" box in their profile. Returns
a hashref with the following keys:

  Status          => Their marital status
  'Here for'      => What they're on MySpace for
  Orientation     => Their sexual orientation
  Hometown        => Their hometown
  'Body type'     => Their body type
  Ethnicity       => Their race
  Religion        => Their religion
  'Zodiac Sign'   => Their star sign
  'Smoke / Drink' => Self-explanatory
  Children        => If they have children
  Education       => Their education level

Values will be 'undefined' if the user hasn't specified them.

=head1 BULLETIN METHODS

=head2 getBulletins ([$PAGE])

Gets all the current bulletins for $PAGE (which defaults to 1). Returns an arrayref of hashrefs.
The arrayref is in the same order as the bulletins appeared on the page (newest is first). The
hashrefs contain the details of the bulletin:

  FriendID   => The poster's ID
  Username   => The poster's username
  Date       => The timestamp of the bulletin
  BulletinID => The bulletin's ID
  Subject    => The bulletin's subject

=head2 readBulletin ($BulletinID)

Reads the bulletin C<$BulletinID>. Returns a hashref:

  FriendID => The poster's ID
  Username => The poster's username
  Date     => The timestamp of the bulletin
  Subject  => The bulletin's subject
  Message  => The body of the bulletin

=head2 postBulletin (%FIELDS)

Post a new bulletin. Returns true on success. Pass arguments in hash form:

  Subject => The bulletin's subject
  Message => The bulletin's message
  Body    => An alternative to Message

=head2 deleteBulletin ($BulletinID)

Delete one of your bulletins. Returns true on success.

=head1 KNOWN ISSUES

The module runs kind of slowly. LWP::UserAgent was created to use LWP::ConnCache
to speed up requests. If anybody has any suggestions to increase speed, please
let me know!

The commentFriends() method is kind of buggy.

=head1 CHANGES

B<Version 0.01>

  - Initial release.

=head1 AUTHOR

Cerone Kirsle, administrator -at- kirsle.com

=head1 LICENSE

Released under the same terms as Perl itself.

=cut

1;