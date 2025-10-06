Admin Jail Script for QBox FiveM

Important Notes:

This is a custom-created script, not copied from any paid resource.
You need to set up ACE permissions in your server.cfg (e.g., add_ace group.admin command.adminjail allow, but see documentation for QBox permissions system).
Run the SQL query to create the database table.
Dependencies: qbx_core, ox_lib, oxmysql.
Place this in a resource folder named qbx-adminjail or similar, and ensure it in your server.cfg.
For character kill (CK) integration, you can trigger the jail event externally when a character dies permanently.
Time only counts down when the player is connected and online.
