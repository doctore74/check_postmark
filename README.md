# check_postmark
Get information about postmark data of domain

Configure Postmark for your domain with the instructions on:
https://dmarc.postmarkapp.com

checkmk
--------
https://mathias-kettner.com/
Successfully tested on checkmk RAW version 1.6.0 (stable)

Path
----
- Place this into /omd/sites/<SITE>/local/lib/nagios/plugins/
- Make this script executable!

Usage
----

```
./check_postmark.sh <API-Token> <Request>
  
Possible requests: {verify,record,snippet,reports}

```
