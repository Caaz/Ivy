%plugin = (
# The required key is entirely optional. If 1, when a dependency isn't met it'll kill the bot. The reason this key exists is for plugins like user, lots of things rely on it.
required => 0,
# This commands key is used by the command plugin. It's an easy way to set up commands.
commands => {
	# The keys in this are basically just regex. if you look closely at the command plugin, you'll see it's modified a bit before it's actually used.
	# This command becomes something like /^(?:(~|-))?Say (?<text>.+)\s+?$/i in my bot! (Assuming the command is used in PM!)
	'Say (?<text>.+)' => {
		# The access key defines who can use this command. It's optional.
		# 0 : No account/access
		# 1 : Has a user account
		# 2 : Trusted user or something I don't know
		# 3 : Owner.
		access => 0,
		# The cooldown key is the amount of seconds before a user can use this command again.
		cooldown => 2,
		# The code key contains the code that is executed when this command is used. It's optional too, but it'd be really useless to have a command with no code.
		code => sub {
			my ($handle,$irc,$data,$tmp,$network,$userID) = splice @_,0,6; # This can probably just be @_ but eh.
			# $handle : Globby wobby thing for writing to.
			# $irc : A hash reference containing the following key-value shit...
			#	-	nick : The nickname of the user using this command
			#	-	user : The username of the user...
			#	-	host : The host of the user...
			#	-	type : The type of message. Vaguely certain this will probably only match on PRIVMSG and NOTICE but who knows.
			#	-	where : Where this message is coming from. Either a channel name or the nick of the user if it's a notice/PM
			#	-	msg : The message, with color codes and formatting stripped. This is what's used when it's actually being matched to the regex.
			#	-	rawmsg : The actual message in full, nothing stripped.
			# $data : A hash references to the actual data of the plugin. It gets saved to sample.json in this case.
			# $tmp : A hash reference to temporary data for the plugin. It doesn't get saved, but is kept in memory.
			# $network : The key to the network data. You can use this to get the network information in $ivy{data}{network}{$network}.
			# $userID : The user account ID of the user using this command. It's -1 if the user isn't currently logged in.
			
			# So here's the raw subroutine, defined in main.pl.
			# Taking two parameters, the globby wobby thing, and the text to write. It's a very basic way for sending shit out.
			raw($handle,"PRIVMSG $$irc{where} :$+{text}");
		}
	},
	'WhoAmI' => {
		# setting access to 1 guarantees this command is only usable by people logged in to the user thing.
		access => 1,
		code => sub {
			my ($handle,$irc,$data,$tmp,$network,$userID) = splice @_,0,6;
			# Because access is 1, $userID will never equal -1 so we don't need to bother checking if the user is logged in. That's been handled already.
			my $user = $ivy{data}{user}{db}[ $userID ];
			# Now we've got a hash reference of the user!
			# Which means we can access...
			#	-	access : Access level.
			#	-	id : Basically just the $userID. Redundancy is nice sometimes.
			#	-	password : An array ref! [digest,salt] -- Not like you'd need to access this or anything, baka.
			#	-	name : The name set on this account. If you want to refer to the user, this is a good value to use.
			#	-	recognized : An array ref of nicknames that this user uses.
			#	-	online : A hash reference, containing info you probably won't need. nickname, username, network. Three values you have on hand already.
			raw($handle,"PRIVMSG $$irc{where} :You are $$user{name}, ID $$user{id}, with access $$user{access}. You're known by ".(@{ $$user{recognized} })." nick/s.");
		}
	},
	'Add (?<a>\d+(?:.\d+)?) (?<b>\d+(?:.\d+)?)' => {
		code => sub {
			my ($handle,$irc,$data,$tmp,$network,$userID) = splice @_,0,6;
			# So here we're going to explain the utility hash that's set up.
			my $total = $u{sample}{add}($+{a},$+{b});
			# So we have %u, which is set up by the utility plugin. It gets all the utility keys from each plugin and throws it into that.
			# The alternative to this code is accessing the code directly through the ivy hash
			# Something like... $ivy{plugin}{sample}{utility}{add} is the equivilant to $u{sample}{add}. 
			# Well we have our total, so let's present it to our user, using prism! A plugin that handles translations and colors, all in one.
			$u{prism}{msg}($handle,$$irc{where},'sample.total',{ a=>$+{a}, b=>$+{b}, total=>$total });
			# Let's break this down!
			# $u{prism}{msg} points to $ivy{plugin}{prism}{utility}{msg}
			# $handle is the globby wobby it writes to
			# $$irc{where} is the channel or user the message will be sent to (and also how it figures out what colors and language it should (attempt to) use)
			# 'sample.total' is bascially how it knows what string to use. 
			# It's pointing to $ivy{plugin}{sample}{strings}{ language }{ region }{total}.
			# You don't need to worry about the language and region part, prism will figure out which to use.
			# finally we have this hash at the end, containing a, b, and total.
			# These values are used within the string, shown below.
			# total => 'The sum of {a} and {b} is {total}!'
			# It throws those values into the spots they go, and colors them! Coloring potentially subject to change.
		}
	}
},
# The hook key hooks into actual events that Ivy uses. Unless you're doing something weird you probably won't need to use this. 
hook => sub {
	# Init is called as soon as the plugin has been loaded. At this point, data has been loaded already, but load hasn't been called.
	init => sub {
		my ($data,$tmp) = @_;
		# All hooks always receive data and tmp as their first and second parameters.
		# They're hash references if you weren't paying attention earlier. data is saved to a json file, tmp is not.
		print "Sample init!\n";
	},
	# The load code is called after data is loaded.
	load => sub { print "Sample load!\n"; },
	# save is called after data is saved.
	save => sub { print "Sample save!\n"; },
	# begin is called before Ivy begins connecting, so it's a great time to get user input from STDIN.
	begin => sub {
		my $answer;
		$u{utility}{ask}('How are you doing today?',undef,\$answer);
		# The ask utility is good for this kind of stuff, accepting three parameters. A question, a default answer, and the reference that it will put the answer in.
		print "I'm glad you're $answer!\n";
	},
	# connect is called to add in any connections into $ivy{select}. You can see an example of how this is done in the network plugin.
	connect => sub { print "Sample connect!\n"; },
	# tick is called nearly every second. It's used for a timer plugin I haven't tested yet but I'm sure there's possibly other ways to use it.
	tick => sub {
		# I'm not going to put a print here because it'd be ridiculous. Just believe me.
	},
	# disconnect is called when a disconnection is noticed. This hasn't been entirely worked out yet but it's good enough.
	disconnect => sub {
		my ($data,$tmp,$handle) = @_;
		# unlike other hooks, this receives an extra thingy!
		# The handle is basically the globby wobby thing of the disconnection.
		# What use is this even? Well let's use a utility to get the network's information!
		my $network = $u{network}{valueByHandle}($handle);
		# Thid hash reference contains some valuable information so I'll quickly lay it out
		# host : The host to connect to
		# port : The port it uses
		# nickname : The nickname to use on this network
		# username : The username to use...
		# realname : The realname to use!
		# If you wanted to get this network's key you could have used keyByHandle instead of valueByHandle.
		print "Disconnected from $$network{host}! Do something about that!\n";
	},
	# irc is called every single msg that's read from server! This can be one of the most powerful but most annoying hook to use!
	irc => sub {
		my ($data,$tmp,$handle,$msg) = @_;
		# $msg is the literal raw line that's sent from the server. Newlines have been removed.
		# I don't want to bother working out an example for this. Go look at the network plugin it handles it well.
	}
},
# The utilities key is used for storing helpful code you'll use in this plugin! or other plugins will use.
utilities => {
	# If you've been reading this entire thing in order, you'll know that we used this add utility earlier
	# it's located at $u{sample}{add} or $ivy{plugin}{sample}{utility}{add}.
	add => sub {
		my $total;
		for(@_) { $total+=$_; }
		return $total;
	},
},
# The strings key contains strings, unsurprisingly. In a perfect world I'd have more than en-us here.
strings => {
	en => {
		us => {
			total => 'The sum of {a} and {b} is {total}!'
		}
	}
});