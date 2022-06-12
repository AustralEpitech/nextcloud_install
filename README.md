# nextcloud_install for debian

> **Warning**: set SQL_LOGIN and SQL_PASSWD before launching the script or
> unsafe default values will be set:
```console
export SQL_LOGIN="login"
export SQL_PASSWD="passwd"
export SERVER_NAME="your.server.com"
```

then, run installation script:
```console
curl https://raw.githubusercontent.com/AustralEpitech/nextcloud_install/main/install.sh | sudo bash
```


# TODO:
- [ ] pretty urls
