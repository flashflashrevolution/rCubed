# Certificate Generators

Air requires that all packages are signed.
For development purposes, you can sign it with a self signed certificate,
which is good because CA sourced code signing certificates are pretty expensive.

You will need to run the certificate script from an account with administrator permissions,
and from a shell in administrator mode.
You can open an *elevated* powershell console by:

---

- [Certificate Generators](#certificate-generators)
  - [Running the Scripts](#running-the-scripts)
  - [Certificate](#certificate)
  - [Github Secrets](#github-secrets)

---

## Running the Scripts

- Pressing the <kbd>Windows</kbd> key.
- Typing `powershell`.
- And either:
  - Right clicking and clicking `Run as administrator`.
  - Clicking `Run as Administrator` in the right panel.

---

## Certificate

This is a signed script that creates a Certificate valid for 1 month,
with all of the specifications required for an air package.
If you modify this script, Powershell will complain,
and you may not be able to run it.

## Github Secrets

This is a signed script that creates a BASE64 string of the certificate.
This is utilized by the workflow action for github.
If you modify this script, Powershell will complain,
and you may not be able to run it.
