required => 1,
hook => {
	begin => sub {
		my $data = shift;
		if(!$$data{prefix}) { $u{utility}{ask}('What prefix do you want to use for commands on your bot? This works as a regex prefix.',"(~|-)",\$$data{prefix}); }
		save();
	},
	irc => sub {
		my ($data,$tmp,$handle,$msg) = splice @_,0,4;
		if($msg =~ /^\:(?<nick>.+?)\!(?<user>.+?)\@(?<host>.+?) (?<type>\w+?) (?<where>.+?) \:(?<rawmsg>.+)$/) {
			my $network = $u{network}{keyByHandle}($handle);
			my %parsed = %+;
			my $prefix = "(?:".$$data{prefix}.")";
			if($parsed{where} !~ /^\x23/) { $prefix .= '?'; $parsed{where} = $parsed{nick}; }
			$parsed{msg} = $parsed{rawmsg};
			$u{utility}{stripCodes}(\$parsed{msg});
			foreach my $key (keys %{ $ivy{plugin} }) {
				my $plugin = $ivy{plugin}{$key};
				foreach my $regex (keys %{ $$plugin{commands} }) {
					if($parsed{msg} =~ /^$regex\s*$/i) {
						next if(($$tmp{$regex}) && (time > $$tmp{$regex}));
						$$plugin{commands}{$regex}{code}(
						
							$handle,
							\%parsed,
							$ivy{data}{$key},
							$ivy{tmp}{$key},
							$network
							
						) if $$plugin{commands}{$regex}{code};
						$$tmp{$parsed{user}}{$regex} = time+$$plugin{commands}{$regex}{cooldown} if $$plugin{commands}{$regex}{cooldown};
					}
				}
			}
		}
	}
}