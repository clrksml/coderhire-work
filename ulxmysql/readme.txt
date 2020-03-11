Thank you for purhasing ULX MySQL

This file require a couple of things to be done before it will work.

1. You need a mysql server that allows external connections. (Contact your webhost if unsure)
2. gmsv_mysql_[distro].dll and libmysql.dll these can be found here. http://facepunch.com/showthread.php?t=1220537
3. You to edit mysql.lua file and enter at the top and fill out your mysql creditals for HOST, USER, PASS, NAME, PORT.
4. For you to run the following command in your SERVER CONSOLE "ulx_mysql_sync" is the command and it ONLY should be run once.

After these steps have been complete you can drop mysql.lua into your servers following folder garrysmod/lua/autorun/server/.

This 'script' will ignore writing to txt files it will however initially load and query the database with bans, groups, and users. This should only happend will the ban, group, and user aren't in the datbase.

Please open a ticket here if you encount any problems.
http://coderhire.com/tickets/add/894