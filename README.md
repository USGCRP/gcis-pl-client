gcis-pl-client
==============

This is a Perl client for GCIS, the Global Change Information System.

Installation
============

```
git clone https://github.com/USGCRP/gcis-pl-client.git
cd gcis-pl-client
cpanm --installdeps .
export PERL5LIB=$PERL5LIB:path/to/gcis-pl-client/lib
```

Configuration
============

Credentials are obtained by signing into the GCIS instance and accessing the path `/login_key`  
Credentials should be stored in a YAML file called `~/etc/Gcis.conf`.

This contains URLs and keys, in this format :

```
    - url      : http://data-stage.globalchange.gov
      userinfo : me@example.com:298015f752d99e789056ef826a7db7afc38a8bbd6e3e23b3
      key      : M2FiLTg2N2QtYjhiZTVhM5ZWEtYjNkM5ZWEtYjNkMS00LTgS00LTg2N2QtYZDFhzQyNGUxCg==
    - url      : http://data.globalchange.gov
      userinfo : username:pass
      key      : key
```

Testing
============

```
export GCIS_DEV_URL="your-dev-instance-url"
prove t/
```
