"
Tests for Pele2svg: the options (Pele2svgOptionsTest) and the fixtures that the examples read (Pele2svgExamplesTest). They do not run pele2svg.mjs, so they need neither Node.js nor Bun.

The diagram examples are in Pele2svgExamples (all the examples of pele.run/examples, read from test/fixtures) and Pele2svgFeaturedExamples (the featured ones, one <gtExample> each). The corpus test of pele2svg.mjs itself runs with npm test (test/corpus.test.js).
"
Class {
	#name : 'ManifestPele2svgTests',
	#superclass : 'PackageManifest',
	#category : 'Pele2svg-Tests-Manifest',
	#package : 'Pele2svg-Tests',
	#tag : 'Manifest'
}
