This project contains configuration files and setup script for my preferred
base linux environment.
There's nothing fancy or advanced here - I'm relatively boring when it comes
to customizing my environments as I've found that the more customized you make
things, the more likely it is that something will break.

I have not included any project-specific tools or configuration files (like
java or node) as those would be tracked separately depending on what project 
I'm working on (and I dont want to mix in work-related stuff here).

Some of this is inspired by https://github.com/victoriadrake/dotfiles and its ilk.
I have three objectives with the project:
1. To be able to easily migrate or re-establish my base environment on any
box with ubuntu 22.04 on it by just doing a git clone and running a _few_
scripts to set everything up
2. To be able to easily see what configuration changes I've made over time
and why I've made them
3. To be able to just do a ```git status``` in a single place in order to see whether 
I've changed any of my configuration files since the last time I pushed the repo.  

Items 1 and 2 pretty obviously lead to a solution that puts things in git.
With regard to item 3, this pushed me toward using symlinks so that the system
can find the files where it expects them to be, but where the files actually all 
live under a single directory that is under source control. (If I copied them
to the right places, then I'd have to worry about whether I changed the original
or the copy)

The stuff in this repo is primarily meant to be installed on a clean ubuntu 22.04
installation running in a VM.  It can probably also be used on an AWS ubuntu AMI,
but there may be some differences that need to be accounted for manually.  I like
my VM to have two volumes - a root OS drive and a data drive where anything not
related to the OS goes on the data drive

To migrate to a fresh ubuntu:
1. Provision target with Ubuntu 24.04 and 2nd volume mounted at /data (configurable in )
2. Copy keys and config to ~/.ssh/
   1. At a minimum, you'll need the ssh key for this git repo in order to pull the files
3. git clone git@github.com:chuckhinson/linux-config.git
4. Install ubuntu-desktop if not already present (mostly for deployment on ec2)
   5. reboot if necessary (desktop install may have applied updates that require reboot)
6. cd linux-config
7. ./setup-dotfiles.sh
8. log out and back in
9. ./install-tools.sh


I try to maintain the distinction between .profile and .bashrc and be
deliberate about what goes in each.  Things that should only be done at 
login and/or that can or should be be inherited by all child shells go in \~/.profile.
Anything that doesnt need to be shared by all child shells or that isnt 
inherited from the login shell goes in \~/.bashrc

NOTE: by default, xrdp will not source \~/.profile on startup.If you need that to 
happen, you have three(?) choices that I know of.
1. edit /etc/xrdp/startwm.sh and add code to do that. It just needs to source 
   your $HOME/.profile before it calls Xsession
2. Configure your terminal to launch login sessions 
2. Include a .xsessionrc file in your home directory that sources your .profile
   (havent tested this one yet, so not sure if it works)
