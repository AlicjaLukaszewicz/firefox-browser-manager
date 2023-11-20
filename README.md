# Firefox Browser Manager!
Welcome to the Firefox Browser Manager program!
This program allows you to manage your Firefox browser's history and cookies, as well as search for specific phrases within your browsing history. The program is designed to be easy to use and requires no advanced technical knowledge.

## Usage
To launch the program, simply navigate to the directory where it is saved and double-click on the file `firefox_browser_manager.sh`. Alternatively, you can launch it from the terminal by typing:

`./firefox_browser_manager.sh` 

The program will display a menu with various options, such as deleting your browser history, searching for specific phrases within your history, and displaying your current cookies and history.

### Command-line Options
The program also includes several command-line options, which can be accessed by typing the following commands in the terminal:

-   `-v` or `--version`: displays the version and author information.
-   `-h` or `--help`: displays help on command-line options.
-   `-a` or `--author`: displays author information.
-   `--display-history`: displays your current browsing history.
-   `--display-cookies`: displays your current cookies.
-   `--display-all`: displays both your browsing history and cookies.

## Used packages
The required packages for running this program, are automatically installed when the script is executed.

`zenity` - a utility that provides a simple GUI dialog box interface for shell scripts.

`sqlite3`- serverless database engine that provides a command-line interface for managing and interacting with relational databases.
