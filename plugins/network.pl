required => 1,
hook => {
	connect => sub {
		my $data = shift;
		if(!(keys %{ $data })) {
			print "(network) You don't seem to have any networks set up. Let's create one.\n";
			$u{network}{create}();
			print "The rest of setup is handled via IRC. For more info view the readme.\n";
			print encode_json($data);
		}
		for $key (keys %{ $data }) { $u{network}{connect}($key); }
	},
	irc => sub {
		my ($data,$tmp,$handle,$msg) = splice @_,0,4;
		print "$msg\n";
		if($msg =~ /^\:Nickserv\!.+? NOTICE .+ \:This nickname is registered/i) {
			my $network = $u{network}{valueByHandle}($handle);
			raw($handle,'PRIVMSG Nickserv :id '.$$network{nickserv}) if($$network{nickserv});
			raw($handle,'JOIN #TheFission');
		}
	}
},
utilities => {
	valueByHandle => sub {
		my $handle = shift;
		for my $con (keys %{ $ivy{connection} }) { return $ivy{data}{network}{$con} if($ivy{connection}{$con} == $handle); }
		return 0;
	},
	keyByHandle => sub {
		my $handle = shift;
		for my $con (keys %{ $ivy{connection} }) { return $con if($ivy{connection}{$con} == $handle); }
		return 0;
	},
	connect => sub {
		my $key = shift;
		my $network = $ivy{data}{network}{$key};
		print "Attempting to connect to $key\n" if $ivy{debug};
		my $connection = new IO::Socket::INET(PeerAddr => $$network{host}, PeerPort => $$network{port}, Proto => 'tcp');
		if($@) { warn "Connection to $key failed. Retrying in 30 seconds...\n"; addTimer(time+30, {code => sub { $u{network}{connect}($key); }}); return 0; }
		else { 
			raw($connection,"NICK $$network{nickname}","USER $$network{username} * 0 :$$network{realname}");
			$ivy{connection}{$key} = $connection; 
			$ivy{select}->add($connection);
			return 1; 
		}
	},
	create => sub {
		my $ask = $u{utility}{ask};
		my $net = $ivy{data}{network};
		my $key;
		&$ask("Enter a key to identify this network.",'rizon',\$key);
		&$ask("Host",'irc.rizon.net',\$$net{$key}{host});
		&$ask("Port",'6667',\$$net{$key}{port});
		&$ask("Nickname",'Ivy',\$$net{$key}{nickname});
		&$ask("Username",'Ivy',\$$net{$key}{username});
		&$ask("Realname",'using Ivy',\$$net{$key}{realname});
		&$ask("Nickserv Password",undef,\$$net{$key}{nickserv});
		save();
		return 1;
	}
}