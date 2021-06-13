# R^3 Font Generators

Rather than forcing contributors to subscribe to Adobe Animate,
fonts are packaged in runtime-loaded .swf libraries.
These are only generated once,
or when unicode characters are modified.

---

- [R^3 Font Generators](#r3-font-generators)
  - [Adding Unicode Range to the R3 Unicode Font](#adding-unicode-range-to-the-r3-unicode-font)
  - [Generating a new Font](#generating-a-new-font)
  - [Adding a font to the Embedded Fonts library](#adding-a-font-to-the-embedded-fonts-library)

---

## Adding Unicode Range to the R3 Unicode Font

1. Determine the unicode range you would like to add.
2. Navigate to [master/fonts/NotoSans/src/NotoSans.as](NotoSans/src/NotoSans.as).
3. Add the unicode range in a comment, and edit the unicode string to include your addition.

## Generating a new Font

1. Copy the folder of an existing font project.
2. Copy your OFL licensed font into the assets folder.
   - If you own the license to a font that you would like to add,
     please create an issue before trying to add a font.
3. Rename asconfig.previous-font-name.json to match your new font.
4. In asconfig.your-font-name.json,
   rename the output to the name of your new font.

   ``` json
   "compilerOptions": {
       "output": "bin/Font-NameOfFont.swf"
   }
   ```

5. Compile a release build of asconfig.your-font-name.json, and your font will appear in [bin](bin/).

## Adding a font to the Embedded Fonts library

1. Open <asconfig.embed-fonts.json>
2. Add the relative path to your new font's src directory to both:
   1. source-path
   2. include-sources

3. Compile a release build of <asconfig.embed-fonts.json>,
   your font will appear in [bin](bin/).
4. Note: If this fails to build due to a java heap error, try running asconfigc manually.

   ```zsh
   .\\node_modules\\.bin\\asconfigc.cmd '--sdk', 'c:\airsdk\33.0.2', '--debug=false', '--project', 'l:\git\flashflashrevolution\games\rCubed\fonts\asconfig.embed-fonts.json' '--jvmargs=-Xmx1000m'
   ```
