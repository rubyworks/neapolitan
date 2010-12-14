--- 
name: neapolitan
company: RubyWorks
title: Neapolitan
contact: rubyworks-mailinglist@googlegroups.com
requires: 
- group: []

  name: malt
  version: 0+
- group: 
  - build
  name: syckle
  version: 0+
- group: 
  - test
  name: qed
  version: 0+
- group: 
  - optional
  - test
  name: rdiscount
  version: 0+
- group: 
  - optional
  - test
  name: redcloth
  version: 0+
- group: 
  - optional
  - test
  - document
  name: rdoc
  version: 2.5+
resources: 
  repository: git://github.com/rubyworks/neapolitan.git
  api: http://rubyworks.github.com/neapolitan/docs/api
  wiki: http://wiki.github.com/rubyworks/neapolitan
  home: http://rubyworks.github.com/neapolitan
  work: http://github.com/rubyworks/neapolitan
pom_verison: 1.0.0
manifest: 
- .ruby
- bin/neapolitan
- lib/neapolitan/meta
- lib/neapolitan.rb
- HISTORY.rdoc
- LICENSE
- README.rdoc
- VERSION
version: 0.3.0
copyright: Copyright (c) 2010 Thomas Sawyer
licenses: 
- Apache 2.0
description: Neapolitan is a meta-templating engine. Like a candy store it allows you to pick and choose from a variety of rendering formats in the construction of a single document. Selections include eruby, textile, markdown and many others.
summary: Kid in the Candy Store Templating
authors: 
- Thomas Sawyer
