# R^3 Engine
<!-- ALL-CONTRIBUTORS-BADGE:START - Do not remove or modify this section -->
[![All Contributors](https://img.shields.io/badge/all_contributors-20-orange.svg?style=flat-square)](#contributors-)
<!-- ALL-CONTRIBUTORS-BADGE:END -->

[![Latest Release][latest-release-badge]](https://github.com/flashflashrevolution/rCubed/releases)
![Platform Support][platforms-badge]
![Release][release-status-badge]
![Master][master-status-badge]
[![FFR Discord][discord-badge]](https://discord.gg/ffr)

---

R^3 is the third and latest game engine for **[Flash Flash Revolution](http://www.flashflashrevolution.com/)**, a free online rhythm game that has been played by over 2 million registered users since 2002.

![R^3 Engine Menu](.github/images/landing_page.png)

<details>
  <summary>More images!</summary>

  ![R^3 Engine Gameplay](.github/images/gameplay.png)
  ![R^3 Results - Accuracy](.github/images/results_page_accuracy.png)
  ![R^3 Results - Combo](.github/images/results_page_combo_progress.png)
  
</details>

---

## Table of Contents

- [R^3 Engine](#r3-engine)
  - [Table of Contents](#table-of-contents)
  - [Getting Started](#getting-started)
    - [Prerequisites](#prerequisites)
    - [Fork the Repo](#fork-the-repo)
    - [Configure Git](#configure-git)
    - [Clone your Repo](#clone-your-repo)
    - [Bootstrap the AirSDK](#bootstrap-the-airsdk)
      - [Running the Script](#running-the-script)
    - [Create custom Workspace](#create-custom-workspace)
    - [Install Workspace Extensions](#install-workspace-extensions)
    - [Use AIR SDK](#use-air-sdk)
    - [Build Fonts](#build-fonts)
    - [Debugging](#debugging)
  - [Contributing](#contributing)
  - [Packaging](#packaging)
  - [Contact](#contact)
  - [Contributors ✨](#contributors-)

---

## Getting Started

These instructions will get you a copy of the R^3 Engine up and running on **Windows** for development and testing purposes (Mac and Linux are not supported).

### Prerequisites

- [Visual Studio Code](https://code.visualstudio.com/Download)
- [Git for Windows](https://git-scm.com/download/win)
- [Java Runtime Environment](https://java.com/en/download/)
- [Adobe AIR SDK & Compiler](http://airdownload.adobe.com/air/win/download/32.0/AIRSDK_Compiler.zip) *(v32.0.0.116 is the final Adobe release)*
  - Extract the contents of the zip folder to your computer

### Fork the Repo

Click the ![Fork][fork-icon] Fork button in the header of this repo before continuing. When it's finished, you'll be taken to your copy of the repo.

### Configure Git

- Open Visual Studio Code.
- Press <kbd>Ctrl+`</kbd> to open the terminal.
- Paste the following command:

```bash
git lfs install; git config core.ignorecase false
```

### Clone your Repo

Next you'll need to clone your forked repo to your computer:

- Press <kbd>CTRL+SHIFT+P</kbd> and search for `Git: Clone`.
  - Enter `https://github.com/YOUR_GITHUB_USERNAME/rCubed.git`.
- If successful, a popup will prompt you to open the cloned repo.

### Bootstrap the AirSDK

This prevents an inconsistent compiler error caused by bad air tooling.

#### Running the Script

- Pressing the <kbd>Windows</kbd> key.
- Typing `powershell`.
- Hit enter or click on the application.
- Navigate to your repository directory.
  - ex. `cd L:\git\flashflashrevolution\games\rCubed`
- Run the bootstrapper
  - ex. `.\bootstrap.ps1 "C:\airsdk\32.0.0.116\frameworks\flex-config.xml"`

---

### Create custom Workspace

In order to setup the SDK path locally in a later step, you'll create a custom workspace from the template.

- Make a copy of the `r3.code-workspace` file alongside it, in the root folder.
- Rename the new workspace to anything else but keep the same extension (for example `my-workspace.code-workspace`).

### Install Workspace Extensions

- Open your workspace file.
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
- [Private message](http://www.flashflashrevolution.com/team/) a developer on FFR.

<!-- URL Shortlinks -->

[CONTRIBUTING]: https://github.com/flashflashrevolution/.github/blob/master/CONTRIBUTING.md

<!-- Badge Shortlinks -->

[release-status-badge]: https://github.com/flashflashrevolution/rCubed/workflows/Release/badge.svg
[master-status-badge]: https://github.com/flashflashrevolution/rCubed/workflows/Check/badge.svg
[latest-release-badge]: https://img.shields.io/github/v/release/flashflashrevolution/rcubed?label=rCubed
[discord-badge]: https://discordapp.com/api/guilds/196381154880782336/widget.png?style=shield
[platforms-badge]: https://img.shields.io/badge/platforms-windows-lightgrey

<!-- Image Shortlinks -->

[fork-icon]: https://cdnjs.cloudflare.com/ajax/libs/octicons/4.4.0/svg/repo-forked.svg

## Contributors ✨

Thanks goes to these wonderful people ([emoji key](https://allcontributors.org/docs/en/emoji-key)):

<!-- ALL-CONTRIBUTORS-LIST:START - Do not remove or modify this section -->
<!-- prettier-ignore-start -->
<!-- markdownlint-disable -->
<table>
  <tbody>
    <tr>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/fizzybuzz"><img src="https://avatars2.githubusercontent.com/u/71256193?v=4?s=100" width="100px;" alt="Fission"/><br /><sub><b>Fission</b></sub></a><br /><a href="https://github.com/flashflashrevolution/rCubed/commits?author=fizzybuzz" title="Documentation">📖</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/G-flat"><img src="https://avatars0.githubusercontent.com/u/63449095?v=4?s=100" width="100px;" alt="G-flat"/><br /><sub><b>G-flat</b></sub></a><br /><a href="https://github.com/flashflashrevolution/rCubed/issues?q=author%3AG-flat" title="Bug reports">🐛</a> <a href="#ideas-G-flat" title="Ideas, Planning, & Feedback">🤔</a> <a href="https://github.com/flashflashrevolution/rCubed/commits?author=G-flat" title="Code">💻</a> <a href="https://github.com/flashflashrevolution/rCubed/commits?author=G-flat" title="Documentation">📖</a> <a href="#translation-G-flat" title="Translation">🌍</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/Hakulyte"><img src="https://avatars1.githubusercontent.com/u/63508408?v=4?s=100" width="100px;" alt="Hakulyte"/><br /><sub><b>Hakulyte</b></sub></a><br /><a href="https://github.com/flashflashrevolution/rCubed/issues?q=author%3AHakulyte" title="Bug reports">🐛</a> <a href="#ideas-Hakulyte" title="Ideas, Planning, & Feedback">🤔</a> <a href="#translation-Hakulyte" title="Translation">🌍</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/jh05013"><img src="https://avatars.githubusercontent.com/u/33805449?v=4?s=100" width="100px;" alt="Jaemin Choi"/><br /><sub><b>Jaemin Choi</b></sub></a><br /><a href="#translation-jh05013" title="Translation">🌍</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://pikachucards.com"><img src="https://avatars1.githubusercontent.com/u/2185274?v=4?s=100" width="100px;" alt="Justin"/><br /><sub><b>Justin</b></sub></a><br /><a href="https://github.com/flashflashrevolution/rCubed/issues?q=author%3AXyr00" title="Bug reports">🐛</a> <a href="https://github.com/flashflashrevolution/rCubed/commits?author=Xyr00" title="Code">💻</a> <a href="#ideas-Xyr00" title="Ideas, Planning, & Feedback">🤔</a></td>
      <td align="center" valign="top" width="14.28%"><a href="http:////mproske.com//"><img src="https://avatars1.githubusercontent.com/u/14317828?v=4?s=100" width="100px;" alt="Max Proske"/><br /><sub><b>Max Proske</b></sub></a><br /><a href="https://github.com/flashflashrevolution/rCubed/commits?author=maxproske" title="Code">💻</a> <a href="#ideas-maxproske" title="Ideas, Planning, & Feedback">🤔</a> <a href="https://github.com/flashflashrevolution/rCubed/issues?q=author%3Amaxproske" title="Bug reports">🐛</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/mat100payette"><img src="https://avatars1.githubusercontent.com/u/20545324?v=4?s=100" width="100px;" alt="Oppiie"/><br /><sub><b>Oppiie</b></sub></a><br /><a href="https://github.com/flashflashrevolution/rCubed/issues?q=author%3Amat100payette" title="Bug reports">🐛</a> <a href="#ideas-mat100payette" title="Ideas, Planning, & Feedback">🤔</a> <a href="#translation-mat100payette" title="Translation">🌍</a></td>
    </tr>
    <tr>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/Psycast"><img src="https://avatars1.githubusercontent.com/u/418690?v=4?s=100" width="100px;" alt="Psycast"/><br /><sub><b>Psycast</b></sub></a><br /><a href="https://github.com/flashflashrevolution/rCubed/commits?author=Psycast" title="Code">💻</a> <a href="#ideas-Psycast" title="Ideas, Planning, & Feedback">🤔</a> <a href="https://github.com/flashflashrevolution/rCubed/issues?q=author%3APsycast" title="Bug reports">🐛</a> <a href="https://github.com/flashflashrevolution/rCubed/commits?author=Psycast" title="Documentation">📖</a> <a href="#maintenance-Psycast" title="Maintenance">🚧</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/SalemKitkat"><img src="https://avatars1.githubusercontent.com/u/31890883?v=4?s=100" width="100px;" alt="Salem Kallien"/><br /><sub><b>Salem Kallien</b></sub></a><br /><a href="https://github.com/flashflashrevolution/rCubed/issues?q=author%3ASalemKitkat" title="Bug reports">🐛</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/SmexxxyBeast"><img src="https://avatars0.githubusercontent.com/u/67475645?v=4?s=100" width="100px;" alt="SmexxxyBeast"/><br /><sub><b>SmexxxyBeast</b></sub></a><br /><a href="#ideas-SmexxxyBeast" title="Ideas, Planning, & Feedback">🤔</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/Snupeh"><img src="https://avatars.githubusercontent.com/u/84457245?v=4?s=100" width="100px;" alt="Snupeh"/><br /><sub><b>Snupeh</b></sub></a><br /><a href="#translation-Snupeh" title="Translation">🌍</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/dave936"><img src="https://avatars0.githubusercontent.com/u/50265779?v=4?s=100" width="100px;" alt="SoFast"/><br /><sub><b>SoFast</b></sub></a><br /><a href="https://github.com/flashflashrevolution/rCubed/commits?author=dave936" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/Sploder12"><img src="https://avatars0.githubusercontent.com/u/49347001?v=4?s=100" width="100px;" alt="Sploder12"/><br /><sub><b>Sploder12</b></sub></a><br /><a href="https://github.com/flashflashrevolution/rCubed/commits?author=Sploder12" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/TCHalogen"><img src="https://avatars2.githubusercontent.com/u/27454436?v=4?s=100" width="100px;" alt="TCHalogen"/><br /><sub><b>TCHalogen</b></sub></a><br /><a href="https://github.com/flashflashrevolution/rCubed/issues?q=author%3ATCHalogen" title="Bug reports">🐛</a> <a href="#ideas-TCHalogen" title="Ideas, Planning, & Feedback">🤔</a> <a href="https://github.com/flashflashrevolution/rCubed/commits?author=TCHalogen" title="Code">💻</a></td>
    </tr>
    <tr>
      <td align="center" valign="top" width="14.28%"><a href="http://www.flashflashrevolution.com"><img src="https://avatars2.githubusercontent.com/u/1892473?v=4?s=100" width="100px;" alt="Zageron"/><br /><sub><b>Zageron</b></sub></a><br /><a href="https://github.com/flashflashrevolution/rCubed/commits?author=Zageron" title="Code">💻</a> <a href="#ideas-Zageron" title="Ideas, Planning, & Feedback">🤔</a> <a href="https://github.com/flashflashrevolution/rCubed/issues?q=author%3AZageron" title="Bug reports">🐛</a> <a href="https://github.com/flashflashrevolution/rCubed/commits?author=Zageron" title="Documentation">📖</a> <a href="#infra-Zageron" title="Infrastructure (Hosting, Build-Tools, etc)">🚇</a> <a href="#maintenance-Zageron" title="Maintenance">🚧</a> <a href="#mentoring-Zageron" title="Mentoring">🧑‍🏫</a> <a href="#projectManagement-Zageron" title="Project Management">📆</a> <a href="https://github.com/flashflashrevolution/rCubed/pulls?q=is%3Apr+reviewed-by%3AZageron" title="Reviewed Pull Requests">👀</a> <a href="#tool-Zageron" title="Tools">🔧</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/arcnmx"><img src="https://avatars1.githubusercontent.com/u/13426784?v=4?s=100" width="100px;" alt="arcnmx"/><br /><sub><b>arcnmx</b></sub></a><br /><a href="https://github.com/flashflashrevolution/rCubed/commits?author=arcnmx" title="Code">💻</a> <a href="#ideas-arcnmx" title="Ideas, Planning, & Feedback">🤔</a> <a href="https://github.com/flashflashrevolution/rCubed/issues?q=author%3Aarcnmx" title="Bug reports">🐛</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/goldstinger"><img src="https://avatars1.githubusercontent.com/u/13899258?v=4?s=100" width="100px;" alt="goldstinger"/><br /><sub><b>goldstinger</b></sub></a><br /><a href="https://github.com/flashflashrevolution/rCubed/issues?q=author%3Agoldstinger" title="Bug reports">🐛</a> <a href="#translation-goldstinger" title="Translation">🌍</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/NotSpiralingEnough"><img src="https://avatars.githubusercontent.com/u/114737163?v=4?s=100" width="100px;" alt="nse_"/><br /><sub><b>nse_</b></sub></a><br /><a href="#translation-NotSpiralingEnough" title="Translation">🌍</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/qrrbrbirbel"><img src="https://avatars3.githubusercontent.com/u/67676739?v=4?s=100" width="100px;" alt="qrrbrbirbel"/><br /><sub><b>qrrbrbirbel</b></sub></a><br /><a href="#ideas-qrrbrbirbel" title="Ideas, Planning, & Feedback">🤔</a> <a href="https://github.com/flashflashrevolution/rCubed/issues?q=author%3Aqrrbrbirbel" title="Bug reports">🐛</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/silentsputnik"><img src="https://avatars.githubusercontent.com/u/56483448?v=4?s=100" width="100px;" alt="silentsputnik"/><br /><sub><b>silentsputnik</b></sub></a><br /><a href="#ideas-silentsputnik" title="Ideas, Planning, & Feedback">🤔</a></td>
    </tr>
  </tbody>
</table>

<!-- markdownlint-restore -->
<!-- prettier-ignore-end -->

<!-- ALL-CONTRIBUTORS-LIST:END -->

This project follows the [all-contributors](https://github.com/all-contributors/all-contributors)
specification. Contributions of any kind welcome!
