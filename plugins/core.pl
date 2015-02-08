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
	},
	'refresh' => {
		access => 3,
		code => sub {
			my ($handle,$irc) = splice @_,0,2;
			my $start = time;
			my @errors = @{ $u{core}{refresh}() };
			$u{prism}{msg}($handle,$$irc{where},'core.refreshed',{seconds => time-$start,errors => (@errors+0)});
			for(@errors) { $u{prism}{msg}($handle,$$irc{where},'core.plugin_error',$_); }
		}
	}
},
strings => {
	fun => {
		json => {
			reloaded => '{seconds:{seconds},errors:{errors}}',
			refreshed => '{seconds:{seconds},errors:{errors}}',
			plugin_error => '{plugin:{plugin},message:{message}}',
		}
	},
	en => { 
		us => {
			reloaded => 'Reloaded. [{seconds} seconds] [{errors} errors]',
			refreshed => 'Refreshed. [{seconds} seconds] [{errors} errors]',
			plugin_error => '[{plugin}] {message}',
		}
	}
},
utilities => {
 reload => sub { save(); my $array = loadPlugins(); plugins(['load']); return $array; },
 refresh => sub { delete $ivy{lastUpdated}; delete $ivy{plugin}; save(); my $array = loadPlugins(); plugins(['load']); return $array; }
},