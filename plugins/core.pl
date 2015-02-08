commands => {
	'\!(?<code>.+)' => {
		access => 3,
		code => sub {
			my ($handle,$irc) = splice @_,0,2;
			my $result = eval($+{code});
			my $error = ($@)?$@:1;
			$error =~ s/\n|\r//g;
			$result =~ s/\n|\r//g;
			raw($handle,"PRIVMSG $$irc{where} :".(($result)?$result:$error));
		}
	},
	'reload' => {
		access => 3,
		code => sub {
			my ($handle,$irc) = splice @_,0,2;
			my $start = time;
			my @errors = @{ $u{core}{reload}() };
			$u{prism}{msg}($handle,$$irc{where},'core.reloaded',{seconds => time-$start,errors => (@errors+0)});
			for(@errors) { $u{prism}{msg}($handle,$$irc{where},'core.plugin_error',$_); }
		}
	}
},
strings => {
	en => { 
		us => {
			reloaded => 'Reloaded. [{seconds} seconds] [{errors} errors]',
			plugin_error => '[{plugin}] {message}',
		}
	}
},
utilities => {
 reload => sub { save(); my $array = loadPlugins(); plugins(['load']); return $array; }
},