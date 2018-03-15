# BlueSpice Docker

This container image is ment to host a [BlueSpice](https://bluespice.com) wiki in Docker.

## Setup and configuration

The container expects two volume mounts and a few environment variables to operate correctly.
The volumes are not mandatory but if you want to extend the base installation or add some additional configured you will run in troubles if you don't mount the specified volumes!

### Volumes

The following volumes are predeclared:

* `/config`
* `/extensions`

The `/config` volume is used as an external storage to preserve the `LocalSettings.php` file containing the whole configuration of the underlying MediaWiki (including database connection parameters, plugin configuration and many more).

The `/extensions` volume is used to add 3rt party plugins to the BlueSpice/MediaWiki instance.
If you don't plan to add additional plugins you ignore this volume for now and add it when required.

When you install a new MediaWiki instance you are required to enter the required parameters like database connection, name of the wiki, admin credentials and a few more in a web based wizard which offers you a generated `LocalSettings.php` file that you have to place in the base directory of your MediaWiki installation.
As this is not really practical in a Docker installation of BlueSpice the required parameters have to be passed as environment variables and a tiny script in the container generates the required config file, persists it through the `/config` volume and runs all further steps automatically (database migrations and a few more things).

### Environment variables

The already mentioned environment variables are:

| Variable name | Default value         | Purpose                                 | Required |
|---------------|-----------------------|-----------------------------------------|----------|
| WIKI_URL      | `http://localhost:80` | Public URL the wiki will be accessed at | false    |
| WIKI_NAME     | `BlueSpice`           | Name of the wiki instance               | fase     |
| DB_USER       | `bluespice`           | Username of the DB user                 | true     |
| DB_PASS       | `""`                  | Password of the DB user                 | true     |
| DB_NAME       | `bluespice`           | Name of the DB the wiki will use        | true     |
| DB_PORT       | `3306`                | Port the DB server listens on           | true     |
| DB_SERVER     | `mysql`               | Hostname of the database server         | true     |
| ADMIN_LOGIN   | `admin`               | Username of the initial admin user      | false    |
| ADMIN_PASS    | `bluespice`           | Password of the initial admin user      | false    |

### Startup steps

Everytime a BlueSpice container is started the following steps are executed:

1. Check if `LocalSettings.php` is already present in `/config` volume
2. If not run initial setup
3. Check if `LocalSettings.php` is present now. If not the container is exiting.
4. Check if the required import of BlueSpice is present in `LocalSettings.php` otherwise add it
5. Copying the persisted version of `LocalSettings.php` to the web directory
6. Copying external extensions to the web directory if there are some
7. Execute migrations (e.g. after update or if new extensions were added)
8. Ensure that the web server is able to access all required files by updating the owner of all files in the web directory
9. Starting the Apache2 web server

## Standalone container

The easiest way to run this container is with `docker-compose` because you won't need to pass all required environment variables in a single command.
The following snippet contains a basic `docker-compose.yaml` service definion of a standalone BlueSpice container.
It is assumed that there is external database server with the hostname `mysql` with an user `bluespice` having the password `bluespice` and an **existing** database also called `bluespice`.

> Note that the database **has to be present** when you start the container otherwise the setup will fail!

```yaml
version: '2.3'
services:
  bluespice:
    image: 'knsit/bluespice:latest'
    volumes:
      - ./test/config:/config
      - ./test/extensions:/extensions
    environment:
      - "WIKI_URL=http://localhost:8081"
      - "WIKI_NAME=KNS-BlueSpice"
      - "DB_USER=bluespice"
      - "DB_PASS=bluespice"
      - "DB_NAME=bluespice"
      - "DB_SERVER=mysql"
      - "ADMIN_LOGIN=admin"
      - "ADMIN_PASS=bluespice"
    ports:
      - 8081:80
```

As already mentioned the `/extensions` volume can be omitted but it's highly recommended to create a persistent volume or a bind mount for the `/config` volume as otherwise the generated `LocalSettings.php` file won't be persisted and to regenerate it an empty database will be necessary!
Of course you can still use the web based wizard to create a new configuration file or create one manually.

## Container with MySQL database

The following snippet defines beside of the BlueSpice service also a MySQL database service.
The configured health check ensures that the database setup is completed before the BlueSpice service is started because right now the container won't check if the database is available but just starts the setup which will fail if the database is not available.

The entrypoint tries to validate that the setup was executed successfully and skip any further steps but there may occur errors anyway if the database is not (yet) accessable when the BlueSpice container is starting.

The remaining configuration of the BlueSpice is equivalent to the standalone version.

```yaml
version: '2.3'
services:
  bluespice:
    image: 'knsit/bluespice:latest'
    volumes:
      - ./test/config:/config
      - ./test/extensions:/extensions
    environment:
      - "WIKI_URL=http://localhost:8081"
      - "WIKI_NAME=KNS-BlueSpice"
      - "DB_USER=bluespice"
      - "DB_PASS=bluespice"
      - "DB_NAME=bluespice"
      - "DB_SERVER=mysql"
      - "ADMIN_LOGIN=admin"
      - "ADMIN_PASS=bluespice"
    ports:
      - 8081:80
    depends_on:
        mysql:
          condition: service_healthy
  mysql:
    image: mysql:5.7
    environment:
      - MYSQL_ROOT_PASSWORD=my5qlR00t#
      - MYSQL_DATABASE=bluespice
      - MYSQL_USER=bluespice
      - MYSQL_PASSWORD=bluespice
    healthcheck:
      test: ["CMD", "mysqladmin" ,"ping", "-h", "localhost"]
      timeout: 20s
      retries: 10
```