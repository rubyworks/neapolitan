---
source:
- var
authors:
- name: trans
  email: transfire@gmail.com
copyrights: []
replacements: []
alternatives: []
requirements:
- name: malt
- name: detroit
  groups:
  - build
  development: true
- name: qed
  groups:
  - test
  development: true
- name: rdiscount
  groups:
  - optional
  - test
  development: true
- name: RedCloth
  groups:
  - optional
  - test
  development: true
- name: yard
  groups:
  - optional
  - test
  - document
  development: true
dependencies: []
conflicts: []
repositories:
- uri: git://github.com/rubyworks/neapolitan.git
  scm: git
  name: upstream
resources:
  home: http://rubyworks.github.com/neapolitan
  code: http://github.com/rubyworks/neapolitan
  docs: http://rubydoc.info/gems/neapolitan/frames
  wiki: http://wiki.github.com/rubyworks/neapolitan
extra: {}
load_path:
- lib
revision: 0
created: '2009-08-25'
summary: Kid in the Candy Store Templating
title: Neapolitan
version: 0.3.0
name: neapolitan
description: ! 'Neapolitan is a meta-templating engine. Like a candy store it allows
  you to pick

  and choose from a variety of rendering formats in the construction of a single

  document. Selections include eruby, textile, markdown and many others.'
organization: rubyworks
date: '2011-11-27'
