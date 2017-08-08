# Sorted
>Personal project for setting up a fresh install.


### Usage

To use Sorted, you can use the script using cURL:

```bash
curl -o- https://raw.githubusercontent.com/chrisssycollins/sorted/master/sorted.sh | bash
```

### Install applications on the fly

You can specify applications for homebrew to install: 

```bash
curl -o- https://raw.githubusercontent.com/chrisssycollins/sorted/master/sorted.sh iterm2 atom tower slack google-chrome firefox sketch spectacle | bash
```