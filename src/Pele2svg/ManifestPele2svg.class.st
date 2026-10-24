"
Pele2svg turns Mermaid text into an SVG string, or into an element that GToolkit can show, by running pele2svg.mjs (Node.js or Bun) as an external process.

Pele2svg is the entry point, and Pele2svgError is signalled when a conversion fails. The settings (script, runtime, theme, timeout) are options: Pele2svgOptions holds the defaults and Pele2svgCurrentOptions gives access to the current ones. Pele2svgExamples has one example for each diagram.

See README.md in the repository for installation and for what has been checked.
"
Class {
	#name : 'ManifestPele2svg',
	#superclass : 'PackageManifest',
	#category : 'Pele2svg-Manifest',
	#package : 'Pele2svg',
	#tag : 'Manifest'
}
