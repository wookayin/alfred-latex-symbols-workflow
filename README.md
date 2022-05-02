Alfred LaTeX Symbols Workflow
=============================

Find LaTeX commands for symbols with Alfred.

![LaTeX Symbols](https://raw.github.com/wookayin/alfred-latex-symbols-workflow/master/screenshots/search.png)


## Usage

In Alfred:

```
tex <QUERY>
```

## Install

```
npm install --global alfred-latex-symbols
```

Requires Node.js 14.0+ (ESM).


### Development

If you check out the working copy (e.g., git clone) of the workflow rather than installing via npm, you will need to generate icons.

```
# Make sure that you have LaTeX installed.

gem install --user-install parallel
ruby generate_icons.rb

npm install
```


## Credit

- The list of LaTeX symbols and ruby code for generating icons were brought from [kirel/detexify](https://github.com/kirel/detexify)
- The [alfy](https://github.com/sindresorhus/alfy/) framework

## License

[The MIT License](LICENSE)
