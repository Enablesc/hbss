Schedule script is a SAP Hana automatic backup tool write in pure Shell language.

USAGE :

The main prerrequsite is create a especific database user to manage backups:

su - <SID>adm -c 'hdbsql -n localhost -i 00 -u SYSTEM -p <PASSWORD>'

hdbsql SID=> CREATE USER BACKUP_OPERATOR password <PASSWORD>;
hdbsql SID=> GRANT backup admin,backup operator,catalog read TO BACKUP_OPERATOR;
hdbsql SID=> ALTER USER BACKUP_OPERATOR DISABLE PASSWORD LIFETIME;;
hdbsql H01=> \q

Then, setup a hdbuserstore for backup_operator user. This allow non-interactive use to this scrpt.

su - <SID>adm -c  'hdbuserstore -i SET backup <HOSTNAME>:3<INSTANCE>15 backup_operator'


Now, modify /etc/backup.cfg and set USERSTORE_KEY to BACKUP:

USERSTORE_KEY=BACKUP


Test with

su - <SID>adm -c '/usr/local/bin/backup.sh -ld'
