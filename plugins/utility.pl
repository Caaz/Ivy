%plugin = (
required => 1,
prereq => { modules => ['Digest::Bcrypt','Digest'] },
hook => {
	tick => sub {
		my ($data,$tmp) = splice @_,0,2;
		my $currentTime = time;
		if($$tmp{lastTime}) {
			for my $wTime ((($currentTime-$$tmp{lastTime}) > 1)?($$tmp{lastTime}..$currentTime):($currentTime)) {
				for my $timer (@{ $$tmp{timer}{$wTime} }) { eval { $$timer{code}($wTime,@{ $$timer{args} }); } or warn $@; }
				delete $$tmp{timer}{$wTime};
			}
		}
		$$tmp{lastTime} = $currentTime;
	},
	init => sub { %u = (); for $key (keys %{ $ivy{plugin} }) { $u{$key} = $ivy{plugin}{$key}{utilities} if $ivy{plugin}{$key}{utilities}; } } 
},
utilities => {
	addTimer => sub { 
		my ($data,$tmp) = splice @_,0,2;
		if($_[0] > time) { push(@{ $$tmp{timer}{$_[0]}}, $_[1]); return 1; } 
		else { warn "Time value must be ahead of the current time!"; return 0; } 
	},
	bcrypt => sub {
		# I: Data, Salt
		# O: Digest, Salt
		my $bcrypt = Digest->new('Bcrypt');
		my $salt = '';
		if((!$_[1]) && ($_[1] !~ /^\C{16}$/)) {
			print "Bcrypt: Generating new salt." if $ivy{debug};
			my @shaker = (32..126);
			for(0..15) { $salt .= chr($shaker[rand(@shaker)]); }
		}
		else { $salt = $_[1]; }
		$bcrypt->cost(10);
		$bcrypt->salt($salt);
		$bcrypt->add($_[0]);
		return [$bcrypt->b64digest,$salt];
	},
	ask => sub {
		my ($msg,$default,$ref) = splice @_,0,3;
		print "$msg".(($default)?" ($default)":'')."\n> ";
		chomp($$ref = <STDIN>);
		$$ref = $default unless(length $$ref);
		return 1;
	},
	stripCodes => sub { my $string = shift; $$string =~ s/\003\d{1,2}(?:\,\d{1,2})?|\02|\017|\003|\x16|\x09|\x13|\x0f|\x15|\x1f//g; }
}
);