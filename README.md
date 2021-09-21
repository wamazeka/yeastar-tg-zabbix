# yeastar-zabbix
Template for monitoring SIM's in Yeastar TG gateways and balance checking on RU operators

Main script and ideas from [@AcidVenom](https://gist.github.com/andrewmagaz)
More about in [article](https://habr.com/ru/post/454702/) on Habr

Make some comments in script and little remarks.
For XML template add balance check & graphs for RU GSM operators.  

## Using
1. Add `yeastar-discovery.sh` in  `/usr/lib/zabbix/externalscripts/` 
2. Import `yeastar-zabbix-template.xml` in Zabbix
3. Add template to host
4. Add macros {$TGAPI.PASS} and {$TGAPI.USER} to host
