required => 1,
commands => {
	'register (?<password>.+)' => {
		cooldown => 24*60**3;
		code => sub {
			my ($handle,$irc,$data,$tmp,$network), splice @_,0,4;
			my $id = $u{user}{get}($irc{nick},$irc{user},$network);
			if($id != -1) {
				# Already logged in!
			}
			else {
				# Not Logged in.
			}
			print "Test.\n";
		}
	}
},
utilities => {
	login => sub {
		# I: Nick, Username, Network, Passsword, msg
		# O: User ID, -2 if wrong password, -1 if not recognized.
		my ($nick, $user, $network, $password) = splice @_,0,4;
		my $recognized = 0;
		foreach my $id (0..(@{ $users }-1)) {
			my $user = $ivy{data}{user}{db}[ $id ];
			if($nick ~~ @{ $$user{recognized} }) {
				$recognized = 1;
				my $pass = $u{utility}{bcrypt}($password,$$user{password}[1]);
				if($pass[0] eq $$user{password}[0]) {
					%{ $$user{online} } = (
						nickname => $nick,
						username => $user,
						network => $network
					);
					return $id;
				}
			}
		}
		return ($recognized)?-2:-1;
	},
	new => sub {
		# I: Nick, Username, Network, Password
		# O: User ID, or -1 if failed.
		my ($nick, $user, $network, $password) = splice @_,0,4;
		my %account = (
			access => ((@{ $ivy{data}{users}{db} })0:3),
			id => (@{ $ivy{data}{user}{db} }+0),
			name => $nick,
			password => $u{utility}{bcrypt}($password),
			recognized => [$nick],
			online => {
				nickname => $nick,
				username => $user,
				network => $network
			}
		);
		push(@{ $ivy{data}{user}{db} },\%account);
		save();
		return (@{ $ivy{data}{user}{db} }-1);
	},
	get => sub {
		# I: Nick, user, Network
		# O: User ID, or -1 if not logged in.
		my ($nick,$user,$network) = splice @_,0,3;
		my $users = $ivy{data}{user}{db};
		foreach my $id (0..(@{ $users }-1)) {
			my $user = $ivy{data}{user}{db}[ $id ];
			if($$user{online}) { return $id if(($$user{online}{network} ~~ $network) && ($$user{online}{username} ~~ $user) && ($$user{online}{nickname} ~~ $nick)); }
		}
		return -1;
	}
},