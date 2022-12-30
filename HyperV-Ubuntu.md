# Setting up a Hyper-V VM

This page provides instructions for setting up an Ubuntu virtual machine using Hyper-V.  A bunch of this could be scripted, but I dont
do it often enough to make it worth the time to figure out the powershell scripting that would be needed. I also dont have a machine that doesnt
already have Hyper-V installed where I could test this out, especially since I dont trust that the numerous uninstall/re-install cycles that would
be necessary to test out the scripts wouldnt somehow corrupt my windows installation.

# Create the new Virtual Machine

- Ensure Hyper-V is enabled
    - https://techcommunity.microsoft.com/t5/itops-talk-blog/step-by-step-enabling-hyper-v-for-use-on-windows-10/ba-p/267945
- Download Ubuntu Desktop from https://ubuntu.com/download/desktop  (22.04 LTS)
- From Hyper-V Manager, goto Hyper-V Settings 
    - Under Enhanced Security Mode Policy (in the Server section) make sure Allow Enhanced session mode is checked  
    - Under Enhanced Session Mode (in the User section) ensure Use enhanced session mode is enabled
- Create a new virtual switch for an externa network
    + From Hyper-V Manager, select Virtual Switch Manager
    + Click New virtual newtork swtich
    + Select External and click Create Virtual Switch
    + Provide a name and under External network, select a network adapter
        * You can pick either wired or wireless
        * Do not select anything that has 'virtual' in its name and do not select the Zscaler network adapter
- In Hypver-V Manager create a new VM (DO NOT use Quick Create)
    - Generation 2
    - 4 GB RAM (works well enough for most stuff)
    - Network Connection: Change from Not Connected to the External network switch you created above
    - Virtual Hard Disk Siz: At leat 40GB
        + If using a single disk, you'll probably want at least 100 GB
        + If using two disks (OS and data), you'll just need to configure the root OS disk for now and that needs to be at least 40GB 
    - Install from ISO, point to downloaded ISO
- Select the newly created VM and go to settings
    - under Security, disable Secure Boot
    - under Integration Services, make sure everything is checked (including Guest Services)
- Run powershell as Admin
```  
Get-VMHost | select Name, EnableEnhancedSessionMode
Set-VMHost -EnableEnhancedSessionMode $true  (If previous command says false)
Get-VM - (to see name)
Set-VM -VMName "Ubuntu 22.04 LTS" -EnhancedSessionTransportType HvSocket  (change name to match what you provided above)
```

# Install Ubuntu in the VM

- Start VM, Connect, and install ubuntu
    + Make sure your host machine is NOT connected to vpn
- Setup enhanced session
    - connect to vm and open terminal window
```
  sudo apt-get update
  sudo apt install git
  git clone https://github.com/Hinara/linux-vm-tools.git
  cd ~/linux-vm-tools/ubuntu/22.04/ 
  sudo chmod +x install.sh
  sudo ./install.sh
  sudo reboot 
```
    - (possibly close the Virtual Machine Connection window)
    - reconnect to vm and open terminal window
```
  cd ~/linux-vm-tools/ubuntu/22.04/ 
  sudo ./install.sh   (will pause for a while around 53% complete)
  sudo poweroff
```
- Mount windows filesystem into VM
    + Ensure that the VM is running 
    + Right-click on the VM in Hyper-V Manager and select Edit Session Settings
        * in the Connect dialog, click on Show Options and then select the Local Resources tab
        * Under Local devices and resources, click the More... button
        * Check the box for Windows (C:)
        * Click OK and then Connect to login to the VM
- Verify configuration
    + In the View menu item of the Virtual Machine Connection window, verfiy that Enhanced Session is checked
    + Open a terminal window or the File manager application and verify that you can access your Windows C: drive via the share-drives folder in your Linux home directory
    + Open Firefox and copy/paste the following url - http://cnn.com into the browser
        * this ensures you have network access and that copy paste between host and vm works

    
# Add a second disk to you VM (Optional)

If you would like to have two separate drives (OS drive and data drive), you can add a second drive to you VM at this point.

- Select new VM and go to Settings
- Select SCSI Controller and then Select Hard Drive on the right and click Add
- Click New
    - Select Dynamically Expanding
    - Enter an appropriate name
    - Enter an appropriate sized (probably at least 60 GB, but go for at least 100 if you have room)
- In VM, start the Disks utility (look under Utilities in the GUI)
- Select the second drive, click the gear and select Format partition, provide a name and then format
- Click the Gear again and select Edit Mount Options and modify the mount point as appropriate.  Suggest mounting at /d and scripts in remaining sections assuming disk mounted there
- Click the mount button to mount the disk



