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
With regard to item 3, this pushed me twoard using symlinks so that the system 
can find the files where it expects them to be, but where the files actually all 
live under a single directory that is under source control. (If I copied them
to the right places, then I'd have to worry about whether I changed the original
or the copy)

The stuff in this repo is primarily meant to be installed on a clean ubuntu 22.04
installation running in a VM.  It can probably also be used on an AWS ubuntu AMI,
but there may be some differences that need to be accounted for manually.  I like
my VM to have two volumes - a root OS drive and a data drive where anything not
related to the OS goes on the data drive


Some planning notes to help me remember why things look the way they do:
1. Install/setup vpn
    1. Everything goes under .openvpn, including binaries
    3. link ~/.openvpn to ~/linux-config/.openvpn and add ~/.openvpn/bin to PATH
    4. I think I also need to install openresolve?
1. Install my base toolset
    1. Assume git's already installed (else how are you pulling this repo)
    1. net-tools and ca-certificates packages  (zip/unzip?)
    1. Docker - including daemon.json.  
        1. Link /etc/docker/daemon.json to linux-config?
        2. configure docker to store all of its stuff on the data drive rather than the root OS drive
    3. ~~Sublime~~
        1. ~~https://linuxhint.com/install_sublime_text3_ubuntu/~~
        1. ~~link $HOME/.config/sublime-text-3/Packages/User to $HOME/linux-config/sublime-text-3/Packages/User~~
        1. ~~.gitignore the Package Control files and copy them into $HOME/linux-config/sublime-text-3/Packages/User before linking~~
            1. ~~Maybe use cp --no-clobber to copy only files that we dont have under source control~~
    4. Chrome
        1. I'm making no attempt to save any Chrome configuration/history/etc.  If that's something I need, I'll solve that in a different way since I'm not interested in sharing my browsing habits in a public git repo
    5. Python 3
    6. jq/yq
    7. KeyStore Explorer
    8. kubectl
    9. awscli
    9. vim (Because the one that comes with ubuntu seems to have an odd config and 
       doesnt seem to want to pay attention to my .vimrc.  I'm not vim expert, so 
       this could easily be user error on my part.)
2. Put dotfiles in right place
    1. ~~dofiles live in $HOME/linux-config/dotfiles and are linked into the home directory~~
    2. ~~.profile~~
    3. ~~.bashrc~~
    4. ~~.gitconfig~~
    5. ~~.vimrc~~
    6. .bash_aliases
    

I try to maintain the distinction between .profile and .bashrc and be
deliberate about what goes in each.  Things that should only be done at 
login and/or that can or should be be inherited by child shells go in \~/.profile.  
Anything that doesnt need to be shared by all child shells or that isnt 
inherited from the login shell goes in \~/.bashrc

NOTE: by default, xrdp will not source \~/.profile on startup.If you need that to 
happen, you have three(?) choices that I know of.
1. edit /etc/xrdp/startwm.sh and add code to do that. It just needs to source 
   your $HOME/.profile before it calls Xsession
2. Configure your terminal to launch login sessions 
2. Include a .xsessionrc file in your home directory that sources your .profile
   (havent tested this one yet, so not sure if it works)
