# Isomagic Todos App

<img src=screenshot.png width=400>

Here's an example app that does a couple of neat tricks:

- the server is compiled with bsb-native
- the client is compiled with bsb
- they share some code
- it uses some custom ppxs that are installed via npm
  - `ppx_autoserialize`, which gives us json stringify/parse for free for all
    custom types, as well as nice chrome devtools object printing
  - `ppx_async`, for `async/await` goodness
  - `ppx_guard`, for `guard let` a la swift


#### Here's some chrome devtools
![devtools](devtools.png)


# Refurbishing

1. Need to get `tools` from package.json by getting [jaredly/reason-language-server@1.5.2](https://github.com/jaredly/reason-language-server/releases/tag/1.5.2) which is the last version with `type-digger` in it.

2. Need to update RR, maybe.