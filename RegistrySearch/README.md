# Search the registry for KeyName, PropertyName, PropertyValue or a combination of the above.

From [this post](https://www.reddit.com/r/PowerShell/comments/10x4ff6/help_finding_and_deleting_reg_entry_with_specific/) where a user named [frermanisawesome](https://www.reddit.com/user/frermanisawesome/) inquired about a method
to search the registry to find and deleting reg entry with specific data value.

## Search-Registry

This function can search registry key names, value names, and value data (in a limited fashion). It outputs custom objects that contain the key and the first match type (KeyName, ValueName, or ValueData). 

You set a search string/regex and can specify to search the registry for KeyName, PropertyName, PropertyValue or a combination of the above.

Taking the information posted by OP here's how to search for the requested registry entries:


```
	$SearchString = "ioojdegpcpikaipagfngjlpolhakofkp"

	# Search from this path down with recurse option
	$SearchPath   = "HKLM:\SOFTWARE\Policies\Google\Chrome"

	$Results = Search-Registry -Path $SearchPath -SearchRegex $SearchString -Recurse
	$Results
```

Voila