# What is it?

#### A word of caution and disclaimer at the beginning: 

Since this application can write to your registry, it comes with **absolutely no warranty** of any kind. If your cat dies or a reincarnation of Elvis appears in your backyard after running this program, it's most likely your own fault. I'm not responsible for anything.

#### Ok, fine, I'm still here, what the...?

It's a quick and dirty hack I wrote to fix an annoying issue with registry bloat. Sometimes, Windows installer fails to delete thousands of keys holding information about registered components (=files) of installed packages when un-installing a package. I found some ten-thousands of orphaned registry keys adding about 20-25MB to the registry hive size. That was almost 1/3 of the overall hive size.


## Usage

This program can wipe orphaned registered components when you know the unique ID for such a package. It uses the following registry key (and only this one):

**It requires administrator privileges** to run and has the potential to possibly damage installed software packages. To my best knowledge, removing those registry keys does only affect the Windows MSI installer and not the installed software itself, but you can never fully know. If unsure, do not use it.

The following key and all of its subkeys are accessed (and only those).

	HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\{UID}\Components

The important part is the {UID} part of the registry key. It's part of your security identifier (SID) in string representation and normally looks similar to *S-1-5-18*.

[here](https://docs.microsoft.com/en-us/windows/win32/secauthz/well-known-sids) is a bit more about SIDs and how they are composed. 

The Important part is to find yours. To do so, open registry editor as administrator and navigate to:

    HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData

Under **UserData**, you will find subkeys that look like SIDs. One of them is most likely S-1-5-18 which is the pre-defined SID for the SECURITY_LOCAL_SYSTEM_RID account under which the MSI installer usually runs. It's composed of 1 (fixed version identifer, never changes), 5 (NT_AUTHORITY authority identifier) and 18, indicating the LOCAL_SYSTEM account.

## But why D, why not just an .EXE?

I chose D, because I can and it works. There is no other reason. Currently, there is no pre-compiled .EXE to download, so you have to get a D compiler and build it.

