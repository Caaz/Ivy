#Ivy
Ivy is an IRC bot, made to be extendable with plugins. This code maintains just the core features to run an IRC bot.

##Module Requirements
You'll need several modules to get this up and running correctly.

The main code requires `Cwd`, `IO::Select`, `IO::Socket`, and `JSON`.

Plugins can require modules as well, right now, utility.pl requires `Digest::Bcrypt`.

##Getting Started
Once you have the modules set up, you run the bot either with `perl main.pl`, or by using the `run.sh` or `run.bat` provided.

On first setup, The command plugin will ask you what prefix you want to use for the bot. The default is set to `(~|-)` which if you're not familiar with regex means either ~ or - can be used as a command prefix.

The network plugin will guide you to setting up your initial network to connect to, after that it should begin connecting.

After it's connected, you should then create a user account on the bot to gain access to owner commands. You can do so by private messaging the bot *register _password_* Once that's set up, you can invite the bot to channels, and it'll automatically add them to autojoin so that it'll join them next time it connects.

##Commands
###user.pl
Command | Description
------- | -----
register **password** | Registers a new account tied to your nickname.
login **password** | Logs into an account tied to your nickname.
logout | Logs out of whatever account you're logged into.
setName **name** | Sets a name for your account.
setPassword **password** | Sets a new password for your account.

###core.pl
Command | Description
------- | -----
meta | Displays amount of files, lines, and comments in the code.
! **some code** | Executes perl code.
reload | Reloads any modified plugins
refresh | Reloads all plugins regardless of modified.

###prism.pl
Command | Description
------- | -----
setColors **Primary**,**Secondary** | Sets the colors for the current channel or user using numbers!
setLanguage **locale** | Sets the language for the current channel or user using an en-us format.
