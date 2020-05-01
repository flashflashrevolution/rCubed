# R^3 Engine

![Release][build-status-badge]
[![FFR Discord][discord-badge]](https://discord.gg/ffr)

R^3 is the third and latest game engine for **[Flash Flash Revolution](http://www.flashflashrevolution.com/)**, a free online rhythm game that has been played by over 2 million registered users since 2002.

![R^3 Engine Menu](https://i.imgur.com/7cdoGVt.png) ![R^3 Engine Gameplay](https://i.imgur.com/GLiKTdQ.png)

---

## Table of Contents

- [R^3 Engine](#r3-engine)
  - [Table of Contents](#table-of-contents)
  - [Getting Started](#getting-started)
    - [Prerequisites](#prerequisites)
    - [Fork the Repo](#fork-the-repo)
    - [Configure Git](#configure-git)
    - [Clone your Repo](#clone-your-repo)
    - [Install Workspace Extensions](#install-workspace-extensions)
    - [Use AIR SDK](#use-air-sdk)
    - [Build Fonts](#build-fonts)
    - [Debugging](#debugging)
  - [Contributing](#contributing)
  - [Packaging](#packaging)
  - [Contact](#contact)

---

## Getting Started

These instructions will get you a copy of the R^3 Engine up and running on **Windows** for development and testing purposes  (Mac and Linux are not supported).

### Prerequisites

- [Visual Studio Code](https://code.visualstudio.com/Download)
- [Git for Windows](https://git-scm.com/download/win)
- [Java Runtime Environment](https://java.com/en/download/)
- [Adobe AIR SDK & Compiler](https://www.adobe.com/devnet/air/air-sdk-download.html) *(v32.0.0.116 is the final Adobe release)*
  - Extract the contents of the zip folder to your computer

### Fork the Repo

Click the ![Fork][fork-icon] Fork button in the header of this repo before continuing. When it's finished, you'll be taken to your copy of the repo.

### Configure Git

- Open Visual Studio Code.
- Press <kbd>Ctrl+`</kbd> to open the terminal.
- Paste the following command:

```bash
git lfs install; git config core.ignorecase false; git config core.autocrlf false
```

### Clone your Repo

Next you'll need to clone your forked repo to your computer:

- Press <kbd>CTRL+SHIFT+P</kbd> and search for `Git: Clone`.
  - Enter `https://github.com/YOUR_GITHUB_USERNAME/rCubed.git`.
- If successful, a popup will prompt you to open the cloned repo.

### Install Workspace Extensions

- Open the `r3.code-workspace` file.
- A popup will prompt you to automatically install the recommended extensions (You can install them manually by pressing <kbd>CTRL+SHIFT+X</kbd> and searching).
  - [ActionScript & MXML](vscode:extension/bowlerhatllc.vscode-nextgenas)
  - [Actionscript Tools](vscode:extension/lonewolf.vscode-astools)

Files with the `.as` extension will now automatically format on save (You can manually format by pressing <kbd>ALT+SHIFT+F</kbd>).

### Use AIR SDK

- Press <kbd>CTRL+SHIFT+P</kbd> and search for `ActionScript: Select Workspace SDK`.
  - Select `Add more SDKs to this list...` then select your unzipped folder.

### Build Fonts

- Press <kbd>CTRL+SHIFT+B</kbd> and run `ActionScript: compile release - fonts/asconfig.embed-fonts.json`.

### Debugging

- Press <kbd>F5</kbd>, and the R^3 Engine will launch in Debug mode.

---

## Contributing

Please read through the [FFR Contribution Guidelines][CONTRIBUTING] before opening a pull request.

---

## Packaging

In order to package your app, AIR needs a certificate. Run [GenerateCertificate](certs/GenerateCertificate.ps1) to create it.

---

## Contact

To contact a member of the FFR development team:

- Join the [FFR Discord](https://discord.gg/ffr) and post in the #dev-chitchat channel.
- [Open an issue](https://github.com/flashflashrevolution/rCubed/issues/new/choose) on GitHub.
- [Private message](http://www.flashflashrevolution.com/team/)  a developer on FFR.

[//]: # (The following hidden section is for link shorteners.)

[CONTRIBUTING]: https://github.com/flashflashrevolution/.github/blob/master/CONTRIBUTING.md
[fork-icon]: https://cdnjs.cloudflare.com/ajax/libs/octicons/4.4.0/svg/repo-forked.svg
[build-status-badge]: https://github.com/flashflashrevolution/rCubed/workflows/Release/badge.svg
[discord-badge]: https://discordapp.com/api/guilds/196381154880782336/widget.png?style=shield
