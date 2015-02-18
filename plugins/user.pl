%plugin = (
required => 1,
commands => {
	'setName (?<name>.+)' => {
		code => sub {
			my ($handle,$irc,$data,$tmp,$network) = splice @_,0,5;
			my $name = $+{name};
			my $id = $u{user}{get}($$irc{nick},$$irc{user},$network);
			if($id != -1) {
				my $user = $$data{db}[ $id ];
				$u{prism}{msg}($handle,$$irc{where},'user.name_change',{oldname=>$$user{name},newname=>$name});
				$$user{name} = $name;
				save();
			}
			else { $u{prism}{msg}($handle,$$irc{where},'user.not_logged_in'); }
		}
	},
	'setPassword (?<password>.+)' => {
		code => sub {
			my ($handle,$irc,$data,$tmp,$network) = splice @_,0,5;
			my $password = $+{password};
			my $id = $u{user}{get}($$irc{nick},$$irc{user},$network);
			if($id != -1) {
				my $user = $$data{db}[ $id ];
				$u{prism}{msg}($handle,$$irc{where},'user.password_change');
				$$user{password} = $u{utility}{bcrypt}($password);
				save();
			}
			else { $u{prism}{msg}($handle,$$irc{where},'user.not_logged_in'); }
		}
	},
	'register (?<password>.+)' => {
		cooldown => 12*60**3,
		code => sub {
			my ($handle,$irc,$data,$tmp,$network) = splice @_,0,5;
			my $password = $+{password};
			my $id = $u{user}{get}($$irc{nick},$$irc{user},$network);
			if($id != -1) {
				my $user = $$data{db}[ $id ];
				$u{prism}{msg}($handle,$$irc{where},'user.already_logged_in',{name=>$$user{name},access=>$$user{access}});
			}
			else {
				$id = $u{user}{new}($$irc{nick},$$irc{user},$network,$password);
				if($id != -1) {
					my $user = $$data{db}[ $id ];
					$u{prism}{msg}($handle,$$irc{where},'user.new_account',{id=>$id,access=>$$user{access}});
				}
				else {
					$u{prism}{msg}($handle,$$irc{where},'user.new_account_failed');
				}
			}
		}
	},
	'login (?<password>.+)' => {
		code => sub {
			my ($handle,$irc,$data,$tmp,$network) = splice @_,0,5;
			my $password = $+{password};
			my $id = $u{user}{get}($$irc{nick},$$irc{user},$network);
			if($id != -1) {
				my $user = $$data{db}[ $id ];
				$u{prism}{msg}($handle,$$irc{where},'user.already_logged_in',{name=>$$user{name},access=>$$user{access}});
			}
			else {
				$id = $u{user}{login}($$irc{nick},$$irc{user},$network,$password);
				if($id > -1) {
					my $user = $$data{db}[ $id ];
					$u{prism}{msg}($handle,$$irc{where},'user.logged_in',{name=>$$user{name},id=>$id,access=>$$user{access}});
				}
				elsif($id == -1) { $u{prism}{msg}($handle,$$irc{where},'user.no_account'); }
				elsif($id == -2) { $u{prism}{msg}($handle,$$irc{where},'user.wrong_password'); }
			}
		}
	},
	'logout' => {
		code => sub {
			my ($handle,$irc,$data,$tmp,$network) = splice @_,0,5;
			my $password = $+{password};
			my $id = $u{user}{get}($$irc{nick},$$irc{user},$network);
			if($id != -1) {
				my $user = $$data{db}[ $id ];
				$u{prism}{msg}($handle,$$irc{where},'user.logged_out');
				delete $$data{db}[ $id ]{online};
			}
			else { $u{prism}{msg}($handle,$$irc{where},'user.not_logged_in'); }
		}
	},
},
strings => {
	fun => {
		json => {
			logged_out => "{success:\x04true\x04}",
			logged_in => "{success:\x04true\x04,name:\"{name}\",access:{access}}",
			not_logged_in => "{success:\x04false\x04,error:\"\x04Not logged in\x04\"}",
			already_logged_in => "{success:\x04false\x04,error:\"\x04Already logged in\x04\",name:\"{name}\"}",
			new_account => "{success:\x04true\x04,id:{id},access:{access}}",
			new_account_fail => "{success:\x04fail\x04,error:\"unknown\"}",
			no_account => "{success:\x04fail\x04,error:\"Unrecognized nick.\"}",
			wrong_password => "{success:\x04fail\x04,error:\"Wrong password.\"}",
			name_change => "{success:\x04true\x04,old:\"{oldname}\",new:\"{newname}\"}",
			password_change => "{success:\x04true\x04}",
		}
	},
	en => {
		us => {
			logged_out => 'Logged out.',
			logged_in => 'Logged in as {name}, access {access}.',
			not_logged_in => 'You\'re not currently logged in.',
			already_logged_in => 'You\'re already logged in as {name}.',
			new_account => 'Successfully created a new account with ID {id}, access {access}.',
			new_account_fail => 'Problem when creating account. Complain to the creator of this bot.',
			no_account => 'It doesn\'t seem like you have an account connected to this nickname. Maybe you meant to use the register command instead?',
			wrong_password => 'Wrong Password.',
			name_change => 'Name changed from {oldname} to {newname}.',
			password_change => 'Password updated.',
		}
	},
},
utilities => {
	login => sub {
		# I: Nick, Username, Network, Passsword
		# O: User ID, -2 if wrong password, -1 if not recognized.
		my ($nickname, $username, $network, $password) = splice @_,0,4;
		my $recognized = 0;
		for my $id (0..(@{ $ivy{data}{user}{db} }-1)) {
			my $user = $ivy{data}{user}{db}[ $id ];
			if($nickname ~~ @{ $$user{recognized} }) {
				$recognized = 1;
				my $pass = $u{utility}{bcrypt}($password,$$user{password}[1]);
				if($$pass[0] eq $$user{password}[0]) {
					%{ $$user{online} } = ( nickname => $nickname, username => $username, network => $network );
					return $id;
				}
			}
		}
		return ($recognized)?-2:-1;
	},
	new => sub {
		# I: Nick, Username, Network, Password
		# O: User ID, or -1 if failed.
		my ($nickname, $username, $network, $password) = splice @_,0,4;
		my $usercount = ($ivy{data}{user}{db})?(@{ $ivy{data}{user}{db} }+0):0;
		my %account = (
			access => (($usercount)?1:3),
			id => $usercount,
			name => $nickname,
			password => $u{utility}{bcrypt}($password),
			recognized => [$nickname],
			online => { nickname => $nickname, username => $username, network => $network }
		);
		push(@{ $ivy{data}{user}{db} },\%account);
		save();
		return $usercount;
	},
	get => sub {
		# I: Nick, user, Network
		# O: User ID, or -1 if not logged in.
		my ($nickname,$username,$network) = splice @_,0,3;
		my $usercount = ($ivy{data}{user}{db})?(@{ $ivy{data}{user}{db} }+0):0;
		return -1 if(!$usercount);
		for my $id (0..$usercount) {
			my $user = $ivy{data}{user}{db}[ $id ] or last;
			if($$user{online}) { return $id if(($$user{online}{network} eq $network) && ($$user{online}{username} eq $username) && ($$user{online}{nickname} eq $nickname)); }
		}
		return -1;
	}
}
);