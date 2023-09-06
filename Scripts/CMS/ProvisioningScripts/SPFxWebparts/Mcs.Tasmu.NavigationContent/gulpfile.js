'use strict';

const build = require('@microsoft/sp-build-web');

build.addSuppression(`Warning - [sass] The local CSS class 'ms-Grid' is not camelCase and will not be type-safe.`);
build.addSuppression(`Warning - [sass] The local CSS class 'page-title' is not camelCase and will not be type-safe.`);
build.addSuppression(`Warning - [sass] The local CSS class 'page-description' is not camelCase and will not be type-safe.`);
build.addSuppression(`Warning - [sass] The local CSS class 'search-box' is not camelCase and will not be type-safe.`);
build.addSuppression(`Warning - [sass] The local CSS class 'btn-search' is not camelCase and will not be type-safe.`);
build.addSuppression(`Warning - [sass] The local CSS class 'entity-name' is not camelCase and will not be type-safe.`);
build.addSuppression(`Warning - [sass] The local CSS class 'category-name' is not camelCase and will not be type-safe.`);
build.addSuppression(`Warning - [sass] The local CSS class 'category-items' is not camelCase and will not be type-safe.`);
build.addSuppression(`Warning - [sass] The local CSS class 'category-row' is not camelCase and will not be type-safe.`);
build.addSuppression(`Warning - [sass] The local CSS class 'col-md-4' is not camelCase and will not be type-safe.`);

build.initialize(require('gulp'));
