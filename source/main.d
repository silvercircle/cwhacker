module main;

/++
 + whack all compontents for an installed package
 + quick and dirty
 +
 + dub build --build=release --compiler=dmd --arch=x86_64
 *
 * Usage:
 * 	whacker --pid=XXXXXXXXXXXXXXXX --print=true|false --delete=true|false --maxperrun=N --search=true|false --searchFor="foo"
 * where:
 * 
 * pid: 		The unique package name to search. This is MANDATORY
 * print: 		if true, tell what's happening, otherwise be silent
 * delete: 		if true, the found entries will be delete (caution)
 * search:		if true, search the REG_SZ value for the string given in --searchFor
 * searchFor:	see above.
 +/

import std.stdio, std.string: indexOf;
import std.windows.registry, core.stdc.stdlib: exit;
import std.getopt;

struct Config {
	int			maxPerRun = -1;
	bool		fDelete	  = false;
	bool		fPrint	  = true;
	string		PID 	  = "";
	bool		fSearch	  = true;
	string		searchTerm = "";
	string		UID		   = "";
}

void main(string[] args)
{
	Config cfg = Config();
	string[]	foundKeys;
	uint		uDeleted = 0;

	version(Windows)
	{
		//HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S[..]\Components
		int 			i = 0;
		Value 			thisvalue;

		const GetoptResult stdargs = getopt(args, "maxperrun", &cfg.maxPerRun, "delete",
			&cfg.fDelete, "print", &cfg.fPrint, "PID", &cfg.PID, "search", &cfg.fSearch, "searchFor", &cfg.searchTerm,
			"UID", &cfg.UID);

		if(stdargs.helpWanted) {
			writeln("\nUSAGE:");
			writef(q"[whacker --pid=PID --print=true|false --delete=true|false --maxperrun=N --search=true|false --searchFor="foo"
 
	PID: 		The unique package name to search. MANDATORY
	UID:		The user id string to work on. See README how to find it. MANDATORY
	maxperrun:	do not process more than N entries, defaults to all entries.
	print: 		if true, tell what's happening, otherwise be silent. Optional, default is TRUE
	delete:		if true, the found entries will be deleted (caution). Optional, default is FALSE
	search:		if true, search the REG_SZ value for the string given in --searchFor
	searchFor:	see above.
]");

			exit(0);
		}
		// sanitizing parameters

		if(cfg.PID.length == 0) {
			writeln("No PID was specified, there is nothing to do.");
			writeln("Please use --PID=foo parameter.");
			exit(0);
		}

		if(cfg.UID.length == 0) {
			writeln("No UID string was specified, there is nothing to do.");
			writeln("Please use --UID=foo parameter.");
			exit(0);
		}

		if(cfg.fSearch && cfg.searchTerm.length == 0) {
			writef("Search was enabled (--search=true) but no search term was given.\nUse --searchFor parameter.");
			exit(0);
		}
		writeln(cfg);
		try {
			Key registryKey = Registry.localMachine()
			.getKey("Software")
			.getKey("Microsoft")
			.getKey("Windows")
			.getKey("CurrentVersion")
			.getKey("Installer", REGSAM.KEY_ALL_ACCESS)
			.getKey("UserData", REGSAM.KEY_ALL_ACCESS)
			.getKey("S-1-5-18", REGSAM.KEY_ALL_ACCESS)
			.getKey("Components", REGSAM.KEY_ENUMERATE_SUB_KEYS | REGSAM.KEY_ALL_ACCESS);

			foreach(ref Key k; registryKey.keys) {
				try {
					thisvalue = k.getValue(cfg.PID);
					if(cfg.fSearch) {
						if(indexOf(thisvalue.value_SZ, cfg.searchTerm) == -1) {
							writef("Key = %s, Value = %s - SEARCH TERM NOT FOUND, skipping\n", k.name, thisvalue.value_SZ);
							continue;
						}
					}
					i++;
					if(cfg.fPrint)
						writef("Key = %s, Value = %s\n", k.name, thisvalue.value_SZ);
					
					foundKeys ~= k.name.dup;
				} catch (RegistryException e)
					continue;
				
				if(i >= cfg.maxPerRun && cfg.maxPerRun != -1)
					break;
			}
			writef("Found %d keys to delete.\n", foundKeys.length);
			if(cfg.fDelete) {
				foreach(ref string keyname; foundKeys) {
					writef("Deleting subkey: %s\n", keyname);
					registryKey.deleteKey(keyname);
				}
			} else
				writeln("Dry run, not actually deleting keys from registry.");

			writef("Finished, found %d and deleted %d entries\n", foundKeys.length, uDeleted);
		} catch(RegistryException e) {
			writeln(e);
			writeln("Error opening registry Key HKLM\\Software\\Microsoft\\Windows\\CurrentVersion\\Installer\\UserData");
			writeln("This program needs administator privileges to work.");
			exit(0);
		}
	} else {
		writeln("This programm will only run on a 64bit verson of Windows 7 or higher");
		exit(0);
	}

}
