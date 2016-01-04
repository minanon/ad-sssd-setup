#!/bin/bash

if [ -f "/etc/arch-release" ]
    pacman -Sy sssd
then

elif [ -f "/etc/debian_version" ]
then
    DEBIAN_FRONTEND=noninteractive
    apt-get update
    apt-get install -y vim sssd smbclient --noninteractive
fi

cat <<EOF > /etc/sssd/sssd.conf
[sssd]
config_file_version = 2
domains  = local.ym
services = nss, pam, pac

[domain/local.ym]
id_provider                 = ad
auth_provider               = ad
chpass_provider             = ad
access_provider             = ad
ad_server                   = ad.local.ym
ad_hostname                 = ad.local.ym

cache_credentials           = true

ldap_schema                 = ad
ldap_id_mapping             = True
ldap_access_order           = expire
ldap_account_expire_policy  = ad
ldap_force_upper_case_realm = true
EOF

chmod 600 /etc/sssd/sssd.conf

echo -e "domain local.ym\nnameserver 172.17.0.3" > /etc/resolv.conf

cat <<EOF > /etc/krb5.conf
[libdefaults]
        default_realm    = LOCAL.YM
        dns_lookup_realm = false
        dns_lookup_kdc   = true

[realms]
        LOCAL.YM = {
                kdc            = ad.local.ym
                admin_server   = ad.local.ym
                default_domain = local.ym
        }

[domain_realm]
        .local.ym = LOCAL.YM
        local.ym  = LOCAL.YM
EOF

cat <<EOF > /etc/samba/smb.conf
[global]
    workgroup = LOCAL
    realm = LOCAL.YM
    security = ads
    obey pam restrictions = Yes

    algorithmic rid base = 10000
    template homedir = /home/%U
    template shell = /bin/bash

    kerberos method = secrets and keytab

    client signing = yes
    client use spnego = yes

    password server = AD.LOCAL.YM

#    idmap uid = 10000-19999
#    idmap gid = 10000-19999
#    idmap backend = rid
EOF

mkdir -p /var/lib/samba/private/

net ads join -U Administrator

