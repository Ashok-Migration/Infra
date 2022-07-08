'use strict';

const build = require('@microsoft/sp-build-web');

build.addSuppression(`Warning - [sass] The local CSS class 'ms-Grid' is not camelCase and will not be type-safe.`);
build.addSuppression(`Warning - [sass] The local CSS class 'is-selected' is not camelCase and will not be type-safe.`);
build.addSuppression(`Warning - [sass] The local CSS class 'ms-DetailsHeader-cellTitle' is not camelCase and will not be type-safe.`);
build.addSuppression(/.*filename should end with module.sass or module.scss/gi);

build.initialize(require('gulp'));
