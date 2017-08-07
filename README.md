# JamfMigrator
A tool to migrate data granularly between Jamf Pro servers

![alt text](https://raw.githubusercontent.com/jamfprofessionalservices/JamfMigrator/master/jamf-migrator/images/migrator1.png "JamfMigrator")

Feedback in the GUI gives a simplistic overview of the success of a transfer:
* Green - everything transferred.
* Yellow - some items transferred.
* Red - nothing transferred.
* White - nothing to transfer.


A more detailed review of migration successes/failures can be found in the log, located in `~/Library/Application Support/jamf-migrator/history/<date>_<time>_migration.txt.`

**Note:** the app can also be used to clear out a Jamf server.  Typing the following after launching the app will remove items from the destination server.

```touch ~/Library/Application\ Support/jamf-migrator/DELETE```

**Limitations/requirements to be aware of:**
* Passwords can not be extracted through the API which impacts migrating distribution points, computer management account, account used for LDAP - credentials must be reset on the destination server.
* Only AFP and SMB shares can be migrated.
* Patch management is not available through the API impacting smart groups dependent on patch management extension attributes.
* Buildings - the API only allows the name to be migrated.
* If enpoints (computers, policies, configuration profiles...) have duplicate names on the source server issues will arise if the app is used to update those items from the source to destination server.

**Important:**<p>
* There are many dependancies between items, if they are not met transfers fail.  For example, if a policy is site specific the site must be migrated before the policy; if a distribution point has a building and/or department defined those need to migrate first...  If everything is migrated the order of sections is already taken care of, if you choose not to move some items that's where you can have issues.
* The selective migration still needs some work.  App is easily crashed by dragging objects other than those from the source server to the destination server.


## History
**jamf-migrator v1.2.1**<p>
* fixed issue where app would hang if last/only item migrated had no endpoints.
* credentials no longer needed for source server when removing data.


**jamf-migrator v1.2.0**<p>
* Fixed the issue migrating computers with the xprotect tag having no value.
* Selective migration now lists endpoints alpha-numeric.
* Added debug logging. To enable, launch the app from terminal:

```…/jamf-migrator.app/Contents/MacOS/jamf-migrator –debug```

* Debug info is added to the history file
* Easily open the history folder from View on the menu bar, or command+L

