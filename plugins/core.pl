commands => {
	'accessTest' => {
		access => 3,
		code => {
			raw($_[0],"PRIVMSG #TheFission :Congrats, this should only be possible with level 3 access.");
		}
	},
	'\!(?<code>.+)' => {
		code => sub {
			my ($handle,$irc,$data,$tmp,$network) = splice @_,0,5;
			my $code = $+{code};
			if($$irc{nick} =~ /Caaz/i) {
				eval($code);
				warn "Eval failed:$@" if $@;
			}
		}
	},
	'reload' => {
		code => sub {
			print "Reloading.\n";
			$u{core}{reload}();
		}
	}
},
utilities => {
 reload => sub { save(); my $hash = loadPlugins(); plugins(['load']); return $hash; }
},