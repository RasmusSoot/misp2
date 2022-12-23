# AdminTool

This is the source code for the utility jar `AdminTool.jar` that is located in the directory `/usr/xtee/app` in a
MISP2 installation.

The utility is used to add or remove administrator accounts to the web application of MISP2. For more
information on the utility and how to use it, please refer to the [user manual](./manual.md).


## Building the package

The package can be built from the root directory by running the following command:

```bash
./gradlew :admin-tool:shadowJar
```