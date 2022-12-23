# MISP2 development environment

The development environment is set up using docker compose, with two containers:

 * `misp` - which contains the Tomcat server that houses both the MISP2 web application
   as well as the Orbeon installation.
 * `db` - which contains the Postgres instance that houses the MISP2 database. The container
   maps the database data to a volume so that re-creating the containers does not cause the
   setup to be lost.

## Running the environment

The environment can be started with the following command:

```bash
docker compose up -d misp db
```

The environment can be stopped with the following command:
```bash
docker compose down misp db
```

### First run

First deploy the applications as well as the `AdminTool.jar` utility by following the steps outlined below.

If the database has not been initialised, you will need to log in to the `misp` containers
once in has started and add the administrator user.

To log into the container, run the following command:

```bash
docker compose exec misp bash
```

Once inside the container, run the following commands (for more commands, please refer to the
[Admin Tool Manual](../utils/admin-tool/manual.md)):

```bash
cd /utils
./admintool.sh -add
```

This will prompt you to enter the username and password for the administrator user.

### Deploying the web application, Orbeon and AdminTool.jar utility

To deploy the war files for the applications execute the following command:

```bash
mkdir webapps pgdata
docker compose up --build compile
```
